import SwiftUI
import AudioToolbox

// MARK: - ShareSheet wrapper
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
        case .blue: return Color.blue.opacity(0.7)
        case .purple: return Color.purple.opacity(0.7)
        case .pink: return Color.pink.opacity(0.7)
        }
    }
    var strokeColor: Color {
        switch self {
        case .blue: return Color.blue
        case .purple: return Color.purple
        case .pink: return Color.pink
        }
    }
}

// MARK: - Main View
struct PuzzleGridView: View {
    @AppStorage("bestScore") private var bestScore: Int = Int.max
    @State private var tiles: [Int] = []
    @State private var moves: Int = 0
    @State private var isSolved: Bool = false
    @State private var selectedColor: TileColorOption = .blue
    @State private var showShare: Bool = false

    private var columns: [GridItem] {
        Array(repeating: .init(.flexible(), spacing: 8), count: 4)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                gameGrid
            }
            fabButton
            if isSolved {
                solveOverlay
            }
        }
        .sheet(isPresented: $showShare) {
            ShareSheet(items: ["I solved SmartSlide in \(moves) moves!"])
        }
        .onAppear(perform: newGame)
    }

    // MARK: Header
    private var header: some View {
        HStack(spacing: 12) {
            Image("logo").resizable().scaledToFit().frame(width: 40, height: 40)
            Text("SmartSlide")
                .font(.title).fontWeight(.black)
                .foregroundStyle(
                    LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Moves: \(moves)").font(.subheadline)
                Text("Best: \(bestScore == Int.max ? "--" : "\(bestScore)")").font(.subheadline)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground).shadow(radius: 2))
    }

    // MARK: Game Grid
    private var gameGrid: some View {
        VStack(spacing: 16) {
            Picker("Tile Color", selection: $selectedColor) {
                ForEach(TileColorOption.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(tiles.indices, id: \.self) { idx in
                    TileView(
                        number: tiles[idx],
                        fillColor: selectedColor.fillColor,
                        strokeColor: selectedColor.strokeColor
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .onTapGesture { moveTile(at: idx) }
                    .animation(.easeInOut, value: tiles)
                }
            }
            .padding(16)

            Spacer()

            Text("Powered by chaitronix.net")
                .font(.footnote)
                .padding(.bottom)
        }
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
                        .background(Color.green)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(20)
            }
        }
    }

    // MARK: Solve Overlay
    private var solveOverlay: some View {
        Group {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("🎉 Congratulations! 🎉")
                    .font(.title).fontWeight(.bold)
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
        }
        .transition(.scale.animation(.spring()))
    }

    // MARK: Game Logic
    private func newGame() {
        var arr: [Int]
        repeat { arr = Array(1...15) + [0]; arr.shuffle() } while !isSolvable(arr)
        withAnimation { tiles = arr }
        moves = 0
        isSolved = false
    }

    private func moveTile(at index: Int) {
        guard let blank = tiles.firstIndex(of: 0) else { return }
        if adjacentIndices(of: blank).contains(index) {
            withAnimation { tiles.swapAt(index, blank) }
            AudioServicesPlaySystemSound(1104)
            moves += 1
            checkSolved()
        }
    }

    private func checkSolved() {
        if tiles == Array(1...15) + [0] {
            isSolved = true
            AudioServicesPlaySystemSound(1016)
            if moves < bestScore { bestScore = moves }
        }
    }

    private func adjacentIndices(of idx: Int) -> [Int] {
        let row = idx / 4, col = idx % 4
        return [(-1,0),(1,0),(0,-1),(0,1)].compactMap { dr, dc in
            let r = row + dr, c = col + dc
            guard (0..<4).contains(r), (0..<4).contains(c) else { return nil }
            return r * 4 + c
        }
    }

    private func isSolvable(_ tiles: [Int]) -> Bool {
        let inv = tiles.filter { $0 > 0 }.enumerated().reduce(0) { sum, pair in
            let (i, val) = pair
            return sum + tiles[(i+1)...].filter { $0 > 0 && val > $0 }.count
        }
        let blankRow = tiles.firstIndex(of: 0)! / 4 + 1
        let fromBottom = 4 - (blankRow - 1)
        return (fromBottom % 2 == 0) ? (inv % 2 != 0) : (inv % 2 == 0)
    }
}

// MARK: - Tile View
struct TileView: View {
    let number: Int
    let fillColor: Color
    let strokeColor: Color

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

struct PuzzleGridView_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleGridView()
    }
}
