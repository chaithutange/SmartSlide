import SwiftUI
import AudioToolbox
import Combine

// MARK: - Share Sheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Tile Color Options
enum TileColorOption: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case blue = "Blue", purple = "Purple", pink = "Pink"

    var fillColor: Color {
        switch self {
        case .blue:   return Color.blue.opacity(0.8)
        case .purple: return Color.purple.opacity(0.8)
        case .pink:   return Color.pink.opacity(0.8)
        }
    }
    var strokeColor: Color {
        switch self {
        case .blue:   return Color.blue
        case .purple: return Color.purple
        case .pink:   return Color.pink
        }
    }
}

// MARK: - Settings / Onboarding View
struct SettingsView: View {
    @AppStorage("playerName") var playerName: String = ""
    @AppStorage("gridSize") var gridSize: Int = 3  // default to 3×3
    @AppStorage("timedMode") var timedMode: Bool = false
    @AppStorage("tileColor") var tileColorRaw: String = TileColorOption.blue.rawValue
    @AppStorage("soundOn") var soundOn: Bool = true               // <-- sound toggle
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Profile")) {
                    TextField("Player Name (optional)", text: $playerName)
                }
                Section(header: Text("Game Settings")) {
                    Picker("Grid Size", selection: $gridSize) {
                        Text("3 × 3").tag(3)
                        Text("4 × 4").tag(4)
                        Text("5 × 5").tag(5)
                    }
                    Toggle("Timed Mode", isOn: $timedMode)
                }
                Section(header: Text("Appearance")) {
                    Picker("Tile Color", selection: $tileColorRaw) {
                        ForEach(TileColorOption.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                }
                Section(header: Text("Sound")) {                        // <-- new section
                    Toggle("Sound Effects", isOn: $soundOn)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Main Puzzle View
struct PuzzleGridView: View {
    // Persistent Settings
    @AppStorage("playerName") private var playerName: String = ""
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @AppStorage("gridSize") private var gridSize: Int = 3    // default to 3×3
    @AppStorage("timedMode") private var timedMode: Bool = false
    @AppStorage("tileColor") private var tileColorRaw: String = TileColorOption.blue.rawValue
    @AppStorage("soundOn") private var soundOn: Bool = true    // <-- read setting
    @AppStorage("bestScore") private var bestScore: Int = Int.max

    // Transient State
    @State private var tiles: [Int] = []
    @State private var moves: Int = 0
    @State private var isSolved: Bool = false
    @State private var showSettings: Bool = false
    @State private var showShare: Bool = false
    @State private var elapsedTime: Int = 0
    @State private var timerCancellable: AnyCancellable?

    // Computed Properties
    private var selectedColor: TileColorOption { TileColorOption(rawValue: tileColorRaw) ?? .blue }
    private var totalTiles: Int { gridSize * gridSize }
    private var columns: [GridItem] { Array(repeating: .init(.flexible(), spacing: 8), count: gridSize) }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                gameGrid
                Spacer(minLength: 20)
                // Fixed Footer
                Link("Powered by chaitronix.net", destination: URL(string: "https://chaitronix.net")!)
                    .font(.footnote)
                    .padding(.bottom, 8)
            }
            fabButton
            if isSolved { victoryOverlay }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showShare) { ShareSheet(items: ["I solved SmartSlide in \(moves) moves!"]) }
        .onAppear {
            if !hasOnboarded { showSettings = true; hasOnboarded = true }
            startTimerIfNeeded(); newGame()
        }
        .onChange(of: timedMode) { _ in startTimerIfNeeded() }
        .onChange(of: gridSize) { _ in newGame() }
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
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(selectedColor.fillColor)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground).shadow(radius: 2))
    }

    // MARK: Game Grid
    private var gameGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<totalTiles, id: \.self) { idx in
                let number = idx < tiles.count ? tiles[idx] : 0
                TileView(number: number,
                         fillColor: selectedColor.fillColor,
                         strokeColor: selectedColor.strokeColor)
                    .aspectRatio(1, contentMode: .fit)
                    .onTapGesture { moveTile(at: idx) }
                    .animation(.easeInOut, value: tiles)
            }
        }
        .padding(16)
    }

    // MARK: Floating Action Button
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

    // MARK: Victory Overlay
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
                    Button("Share") { showShare = true }
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

    // MARK: Game Logic
    private func newGame() {
        var arr: [Int] = Array(1..<totalTiles) + [0]
        repeat { arr.shuffle() } while !isSolvable(arr)
        withAnimation { tiles = arr }
        moves = 0; isSolved = false
    }
    private func moveTile(at i: Int) {
        guard i < tiles.count,
              let blank = tiles.firstIndex(of: 0),
              adjacentIndices(of: blank).contains(i)
        else { return }
        tiles.swapAt(i, blank)
        if soundOn { AudioServicesPlaySystemSound(1104) }     // <-- conditional sound
        moves += 1
        checkSolved()
    }
    private func checkSolved() {
        if tiles == Array(1..<totalTiles) + [0] {
            isSolved = true
            if soundOn { AudioServicesPlaySystemSound(1016) } // <-- conditional sound
            if moves < bestScore { bestScore = moves }
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

// MARK: - Tile View
struct TileView: View {
    let number: Int; let fillColor: Color; let strokeColor: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(number == 0 ? Color.clear : fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(strokeColor, lineWidth: number == 0 ? 1 : 0)
                )
            if number != 0 {
                Text("\(number)")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .shadow(radius: 1)
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
    }
}

// MARK: - Int parity
private extension Int {
    var isEven: Bool { self % 2 == 0 }
    var isOdd: Bool { !isEven }
}

struct PuzzleGridView_Previews: PreviewProvider {
    static var previews: some View { PuzzleGridView() }
}
