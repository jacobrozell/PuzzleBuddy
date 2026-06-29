//
//  PuzzleRandomPicker.swift
//  Puzzle Buddy
//
//  Backs the "Pick my next puzzle" mode (Wheel-of-Fortune random selector).
//  Draws from To-Do (and optionally In-Progress) puzzles with optional
//  tag and piece-count filters.
//

import Foundation

// MARK: - PuzzleRandomPicker

enum PuzzleRandomPicker {
    /// Returns puzzles eligible for a random pick. Wishlist puzzles are excluded.
    static func eligible(
        from puzzles: [Puzzle],
        includeInProgress: Bool,
        pieceCountFilter: PuzzleListPieceCountFilter,
        tagFilter: String?
    ) -> [Puzzle] {
        puzzles.filter { puzzle in
            switch puzzle.status {
            case .wishlist, .completed, .abandoned:
                return false
            case .todo:
                break
            case .inProgress:
                if !includeInProgress { return false }
            }
            if !pieceCountFilter.matches(puzzle) { return false }
            if let tagFilter,
               !puzzle.tags.contains(where: { $0.caseInsensitiveCompare(tagFilter) == .orderedSame }) {
                return false
            }
            return true
        }
    }

    /// Picks a single puzzle at random, avoiding `excluding` when the pool allows.
    static func pick<R: RandomNumberGenerator>(
        from pool: [Puzzle],
        excluding: UUID?,
        using generator: inout R
    ) -> Puzzle? {
        guard !pool.isEmpty else { return nil }
        if pool.count > 1, let excluding {
            let fresh = pool.filter { $0.id != excluding }
            if !fresh.isEmpty {
                return fresh.randomElement(using: &generator)
            }
        }
        return pool.randomElement(using: &generator)
    }

    static func pick(from pool: [Puzzle], excluding: UUID? = nil) -> Puzzle? {
        var generator = SystemRandomNumberGenerator()
        return pick(from: pool, excluding: excluding, using: &generator)
    }
}
