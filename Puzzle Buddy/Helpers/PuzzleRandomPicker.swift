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
    /// Returns the set of puzzles eligible for a random pick given the current filters.
    /// Wishlist puzzles are excluded — you can't work on something you don't own yet.
    static func eligible(
        from puzzles: [Puzzle],
        includeInProgress: Bool,
        pieceCountFilter: PuzzleListPieceCountFilter,
        tagFilter: String?
    ) -> [Puzzle] {
        puzzles.filter { puzzle in
            switch puzzle.status {
            case .todo:
                break
            case .inProgress:
                if !includeInProgress { return false }
            case .completed:
                return false
            }
            if !pieceCountFilter.matches(puzzle) { return false }
            if let tagFilter, !puzzle.tags.contains(where: { $0.caseInsensitiveCompare(tagFilter) == .orderedSame }) {
                return false
            }
            return true
        }
    }

    /// Picks a single puzzle at random from `pool`, avoiding `excluding` when possible
    /// (so repeated spins feel fresh). Falls back to any eligible puzzle if `excluding`
    /// is the only option.
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
