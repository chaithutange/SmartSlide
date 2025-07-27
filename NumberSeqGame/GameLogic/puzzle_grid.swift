import SwiftUI
import AudioToolbox

// MARK: – Tile Color Options
enum TileColorOption: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"

    var fillColor: Color {
        switch self {
        case .blue:   return Color.blue.opacity(0.7)
        case .purple: return Color.purple.opacity(0.7)
        case .pink:   return Color.pink.opacity(0.7)
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

struct PuzzleGridView: View {
    // MARK: – Persistent State
    @AppStorage("bestScore") private var bestScore: Int = Int.max

    // MARK: – Transient State
    @State private var tiles: [Int] = []
    @State private var moves: Int = 0
    @State private var isSolved: Bool = false
    @State private var selectedColor: TileColorOption = .blue

    // 4×4 grid layout
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Enhanced Header
                HStack(spacing: 12) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                    Text("SmartSlide")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    Color(UIColor.systemBackground)
                        .shadow(radius: 2)
                )

                // Main game UI
                VStack(spacing: 16) {
                    // Controls & Scores
                    HStack {
                        Button(action: newGame) {
                            Text("New Game")
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .shadow(radius: 3)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Moves: \(moves)")
                                .font(.subheadline)
                            Text("Best: \(bestScore == Int.max ? "--" : "\(bestScore)")")
                                .font(.subheadline)
                        }
                    }
                    .padding(.horizontal)

                    // Color Picker
                    Picker("Tile Color", selection: $selectedColor) {
                        ForEach(TileColorOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // Puzzle Grid
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(tiles.indices, id: \.self) { index in
                            let number = tiles[index]
                            TileView(
                                number: number,
                                fillColor: selectedColor.fillColor,
                                strokeColor: selectedColor.strokeColor
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .onTapGesture { moveTile(at: index) }
                            .animation(.easeInOut, value: tiles)
                            .transition(.move(edge: .bottom))
                        }
                    }
                    .padding(16)

                    Spacer()

                    // Powered By
                    HStack {
                        Spacer()
                        Text("Powered by ")
                            .font(.footnote)
                        Link("chaitronix.net", destination: URL(string: "https://chaitronix.net/")!)
                            .font(.footnote)
                        Spacer()
                    }
                    .padding(.bottom)
                }
                .onAppear(perform: newGame)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: moves)
            }

            // Congratulations overlay
            if isSolved {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("🎉 Congratulations! 🎉")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .transition(.scale)
                    Text("You solved the puzzle in \(moves) moves.")
                        .font(.headline)
                    Button(action: newGame) {
                        Text("Play Again")
                            .font(.headline)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.8))
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
    }

    // MARK: – Game Logic
    private func newGame() {
        var newTiles: [Int]
        repeat {
            newTiles = Array(1...15) + [0]
            newTiles.shuffle()
        } while !isSolvable(newTiles)
        withAnimation { tiles = newTiles }
        moves = 0
        isSolved = false
    }
    private func moveTile(at index: Int) {
        guard let blank = tiles.firstIndex(of: 0) else { return }
        let valid = adjacentIndices(of: blank)
        if valid.contains(index) {
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
    private func adjacentIndices(of index: Int) -> [Int] {
        let row = index / 4, col = index % 4
        return [(-1,0),(1,0),(0,-1),(0,1)].compactMap { dr, dc in
            let r = row + dr, c = col + dc
            guard (0..<4).contains(r), (0..<4).contains(c) else { return nil }
            return r * 4 + c
        }
    }
    private func isSolvable(_ tiles: [Int]) -> Bool {
        let inv = tiles.filter { $0 != 0 }.enumerated().reduce(0) { sum, pair in
            let (i,val) = pair
            return sum + tiles[(i+1)...].filter { $0 != 0 && val > $0 }.count
        }
        let blankRow = tiles.firstIndex(of: 0)! / 4 + 1
        let rowFromBottom = 4 - (blankRow - 1)
        return (rowFromBottom % 2 == 0) ? (inv % 2 != 0) : (inv % 2 == 0)
    }
}

// MARK: – Tile View with Styling
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

struct PuzzleGridView_Previews: PreviewProvider { static var previews: some View { PuzzleGridView() } }
