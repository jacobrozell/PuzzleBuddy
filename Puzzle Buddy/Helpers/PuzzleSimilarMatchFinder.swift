//
//  PuzzleSimilarMatchFinder.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleSimilarMatchFinder {
    /// Soft duplicate hints inspired by IPDb (brand + title, brand + pieces). Does not block saves.
    static func findSimilar(
        name: String,
        source: String?,
        pieces: Int?,
        barcode: String?,
        excludingID: UUID?,
        in puzzles: [Puzzle],
        limit: Int = 3
    ) -> [Puzzle] {
        let normalizedName = normalize(name)
        let normalizedSource = normalize(source)
        let normalizedBarcode = BarcodeNormalizer.normalize(barcode)

        guard !normalizedName.isEmpty || normalizedSource != nil || pieces != nil else {
            return []
        }

        var matches: [Puzzle] = []

        for puzzle in puzzles {
            guard puzzle.id != excludingID else { continue }
            if let normalizedBarcode,
               let existing = BarcodeNormalizer.normalize(puzzle.barcode),
               existing == normalizedBarcode {
                continue
            }

            let puzzleName = normalize(puzzle.name)
            let puzzleSource = normalize(puzzle.source)
            let nameMatches = !normalizedName.isEmpty && puzzleName == normalizedName
            let sourceMatches = normalizedSource != nil && puzzleSource == normalizedSource
            let piecesMatch = pieces != nil && puzzle.pieces == pieces

            let isSimilar =
                (nameMatches && sourceMatches) ||
                (nameMatches && piecesMatch) ||
                (sourceMatches && piecesMatch && !normalizedName.isEmpty && puzzleName == normalizedName)

            if isSimilar {
                matches.append(puzzle)
            }
        }

        return Array(matches.prefix(limit))
    }

    private static func normalize(_ value: String?) -> String {
        guard let value else { return "" }
        return value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
