//
//  HintEngine.swift
//  NumberSeqGame
//
//  Created by Chaithanya Tangellapalli on 8/9/25.
//


import Foundation

enum HintEngine {
    /// Returns the index of the tile you should tap next (adjacent to blank), or nil if none.
    static func nextBestMove(tiles: [Int], grid: Int) -> Int? {
        guard let blank = tiles.firstIndex(of: 0) else { return nil }
        let currentCost = manhattanCost(tiles, grid: grid)

        var bestIndex: Int? = nil
        var bestCost = Int.max

        for i in movableIndices(blank: blank, grid: grid) {
            var sim = tiles
            sim.swapAt(i, blank)
            let cost = manhattanCost(sim, grid: grid)
            // choose the move with lowest cost; prefer improvements
            if cost < bestCost || (bestIndex == nil && cost == bestCost) {
                bestCost = cost
                bestIndex = i
            }
        }

        // If nothing improves, still return the least-bad option so the user isn’t stuck
        return bestIndex
    }

    /// Sum of Manhattan distances of each tile to its goal position
    static func manhattanCost(_ tiles: [Int], grid: Int) -> Int {
        var sum = 0
        for (idx, v) in tiles.enumerated() where v != 0 {
            let goal = v - 1
            let (r, c) = (idx / grid, idx % grid)
            let (gr, gc) = (goal / grid, goal % grid)
            sum += abs(r - gr) + abs(c - gc)
        }
        return sum
    }

    static func movableIndices(blank: Int, grid: Int) -> [Int] {
        let row = blank / grid, col = blank % grid
        return [(-1,0),(1,0),(0,-1),(0,1)].compactMap { dr, dc in
            let r = row + dr, c = col + dc
            guard (0..<grid).contains(r), (0..<grid).contains(c) else { return nil }
            return r * grid + c
        }
    }
}
