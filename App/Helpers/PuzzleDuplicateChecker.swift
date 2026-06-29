//
//  PuzzleDuplicateChecker.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleDuplicateChecker {
    static func findDuplicate(
        barcode: String?,
        excludingID: UUID?,
        in puzzles: [Puzzle]
    ) -> Puzzle? {
        guard let normalized = BarcodeNormalizer.normalize(barcode) else { return nil }

        return puzzles.first { puzzle in
            guard puzzle.id != excludingID else { return false }
            guard let existing = BarcodeNormalizer.normalize(puzzle.barcode) else { return false }
            return existing == normalized
        }
    }
}
