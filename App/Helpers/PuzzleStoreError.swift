//
//  PuzzleStoreError.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleStoreError: LocalizedError {
    case duplicateBarcode(existingPuzzleName: String, barcode: String)

    var errorDescription: String? {
        switch self {
        case .duplicateBarcode(let existingPuzzleName, let barcode):
            return "Another puzzle (\(existingPuzzleName)) already uses barcode \(barcode)."
        }
    }
}
