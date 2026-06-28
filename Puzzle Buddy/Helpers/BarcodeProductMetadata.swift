//
//  BarcodeProductMetadata.swift
//  Puzzle Buddy
//

import Foundation

struct BarcodeProductMetadata: Equatable {
    let title: String?
    let brand: String?
    let pieces: Int?
    let sourcePuzzleID: UUID?
    let sourcePuzzleName: String?

    var suggestedName: String? {
        BarcodeTitleParser.cleanedTitle(title)
    }

    var suggestedPieces: Int? {
        pieces ?? BarcodeTitleParser.pieces(from: title)
    }

    var lookupSourceLabel: String? {
        if let sourcePuzzleName, !sourcePuzzleName.isEmpty {
            return "Previously saved as \(sourcePuzzleName)"
        }
        return "From your saved puzzles"
    }
}
