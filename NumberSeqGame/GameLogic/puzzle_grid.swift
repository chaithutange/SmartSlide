import SwiftUI
import AudioToolbox
import Combine

struct PuzzleGridView: View {
    // Persistent settings
    @AppStorage("playerName") private var playerName: String = ""
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @AppStorage("gridSize") private var gridSize: Int = 3
    @AppStorage("timedMode") private var timedMode: Bool = false
    @AppStorage("tileColor") private var tileColorRaw: String = TileColorOption.blue.rawValue
    @AppStorage("soundOn") private var soundOn: Bool = true
    @AppStorage("bestScore") private var bestScore: Int = Int.max
    @AppStorage("hasShownHint") private var hasShownHint: Bool = false


    // State
    @State private var tiles: [Int] = []
    @State private var moves: Int = 0
    @State private var isSolved: Bool = false
    @State private var showSettings: Bool = false
    @State private var showShare: Bool = false
    @State private var shareItems: [Any] = []
    @State private var elapsedTime: Int = 0
    @State private var timerCancellable: AnyCancellable?
    @State private var showIntro: Bool = false
    @State private var hintTileIndex: Int? = nil
    @State private var hintedIndex: Int? = nil



    // Computed
    private var selectedColor: TileColorOption { TileColorOption(rawValue: tileColorRaw) ?? .blue }
    private var totalTiles: Int { gridSize * gridSize }
    private var columns: [GridItem] { Array(repeating: .init(.flexible(), spacing: 8), count: gridSize) }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                gameGrid
                Spacer(minLength: 20)
                Link("Powered by chaitronix.net", destination: URL(string: "https://chaitronix.net")!)
                    .font(.footnote)
                    .padding(.bottom, 8)
            }
            fabButton
            if isSolved { victoryOverlay }
        }
        // Intro on first launch
        .fullScreenCover(isPresented: $showIntro) {
            IntroView(
                isPresented: $showIntro,
                onOpenSettings: { showSettings = true }
            )
        }
        // Settings sheet
        .sheet(isPresented: $showSettings) { SettingsView() }
        // Share sheet
        .sheet(isPresented: $showShare, onDismiss: { shareItems.removeAll() }) {
            ShareSheet(items: shareItems)
        }
        .id(shareItems.count)
        // Launch logic
        .task {
            if !hasOnboarded {
                showIntro = true
                hasOnboarded = true
            }
            startTimerIfNeeded()
            newGame()
                
            
            if !hasShownHint {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if let blank = tiles.firstIndex(of: 0),
                       let firstMove = adjacentIndices(of: blank).first {
                        hintTileIndex = firstMove
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            hintTileIndex = nil
                            hasShownHint = true
                        }
                    }
                }
            }
        }
        // 👇 Add this right after `.task`
            .onChange(of: gridSize) { _ in
                tiles = []
                moves = 0
                isSolved = false
                DispatchQueue.main.async {
                    newGame()
                }
            }
            .onChange(of: timedMode) { _ in
                startTimerIfNeeded()
            }
    }

    // MARK: Header
    private var header: some View {
        HStack {
            Text("SmartSlide")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(selectedColor.fillColor)
            Spacer()
            VStack(alignment: .trailing) {
                if timedMode { Text("Time: \(elapsedTime)s").font(.subheadline) }
                Text("Moves: \(moves)").font(.subheadline)
                Text("Best: \(bestScore == Int.max ? "--" : "\(bestScore)")").font(.subheadline)
            }
            Button(action: { showHint() }) {
                Image(systemName: "lightbulb")
                    .font(.title2)
                    .foregroundColor(selectedColor.fillColor)
            }
            .buttonStyle(.plain)
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(selectedColor.fillColor)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground).shadow(radius: 2))
    }

    // MARK: Game grid
    private var gameGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<totalTiles, id: \.self) { idx in
                let number = idx < tiles.count ? tiles[idx] : 0
                TileView(
                    number: number,
                    fillColor: (hintedIndex == idx && number != 0)
                               ? Color.yellow.opacity(0.85)
                               : selectedColor.fillColor,
                    strokeColor: selectedColor.strokeColor
                )
                .aspectRatio(1, contentMode: .fit)
                .onTapGesture { moveTile(at: idx) }
                .animation(.easeInOut, value: tiles)
            }
        }
        .padding(16)
        .id(gridSize)  
    }

    // MARK: FAB
    private var fabButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: newGame) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(selectedColor.fillColor)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(20)
            }
        }
    }
    
    private func showHint() {
        guard !isSolved else { return }
        if let idx = HintEngine.nextBestMove(tiles: tiles, grid: gridSize) {
            hintedIndex = idx
            // auto clear after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.hintedIndex = nil
            }
        }
    }

    // MARK: Victory overlay
    private var victoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🎉 Congratulations! 🎉")
                    .font(.title)
                    .fontWeight(.bold)
                Text("You solved the puzzle in \(moves) moves.")
                    .font(.headline)
                HStack(spacing: 16) {
                    Button("Play Again", action: newGame)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    Button("Share") { share() }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(24)
            .background(Material.ultraThin)
            .cornerRadius(12)
            .shadow(radius: 10)
            .transition(.scale.animation(.spring()))
        }
    }

    // MARK: Game logic
    private func newGame() {
        hintedIndex = nil
        var arr: [Int] = Array(1..<totalTiles) + [0]
        repeat { arr.shuffle() } while !isSolvable(arr)
        withAnimation { tiles = arr }
        moves = 0
        isSolved = false
    }

    private func moveTile(at i: Int) {
        hintedIndex = nil
        guard i < tiles.count,
              let blank = tiles.firstIndex(of: 0),
              adjacentIndices(of: blank).contains(i)
        else { return }
        tiles.swapAt(i, blank)
        if soundOn { AudioServicesPlaySystemSound(1104) }
        moves += 1
        checkSolved()
    }

    private func checkSolved() {
        if tiles == Array(1..<totalTiles) + [0] {
            isSolved = true
            if soundOn { AudioServicesPlaySystemSound(1016) }
            if moves < bestScore { bestScore = moves }
        }
    }

    // MARK: Share logic
    private func share() {
        let text = "I solved SmartSlide in \(moves) moves!"

        // Try to render the key window into an image
        var items: [Any] = [text]
        if let window = UIApplication.shared.keyWindow {
            let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
            let img = renderer.image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            items.insert(img, at: 0)
        }

        // Update items first, then present on next runloop
        self.shareItems = items
        DispatchQueue.main.async {
            self.showShare = true
        }
    }

    // MARK: Timer
    private func startTimerIfNeeded() {
        timerCancellable?.cancel()
        elapsedTime = 0
        if timedMode {
            timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in elapsedTime += 1 }
        }
    }

    // MARK: Helpers
    private func adjacentIndices(of idx: Int) -> [Int] {
        let row = idx / gridSize, col = idx % gridSize
        return [(-1,0),(1,0),(0,-1),(0,1)].compactMap { dr, dc in
            let r = row + dr, c = col + dc
            return (0..<gridSize).contains(r) && (0..<gridSize).contains(c) ? r*gridSize + c : nil
        }
    }

    private func isSolvable(_ arr: [Int]) -> Bool {
        let inv = arr.filter { $0 > 0 }.enumerated().reduce(0) { sum, p in
            sum + arr[(p.0+1)...].filter { $0 > 0 && p.1 > $0 }.count
        }
        let blankRow = arr.firstIndex(of: 0)! / gridSize + 1
        let fromBottom = gridSize - (blankRow - 1)
        return gridSize.isMultiple(of: 2)
            ? ((fromBottom.isMultiple(of: 2) ? inv.isOdd : inv.isEven))
            : inv.isEven
    }
}

// MARK: - Int parity
private extension Int {
    var isEven: Bool { self % 2 == 0 }
    var isOdd: Bool { !isEven }
}
