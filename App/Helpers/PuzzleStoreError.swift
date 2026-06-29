//
//  PuzzleStoreError.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleStoreError: LocalizedError {
    case duplicateBarcode(existingPuzzleName: String, barcode: String)
    case recordNotFound
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .duplicateBarcode(let existingPuzzleName, let barcode):
            return "Another puzzle (\(existingPuzzleName)) already uses barcode \(barcode)."
        case .recordNotFound:
            return "That puzzle is no longer in your collection."
        case .saveFailed:
            return "Could not save changes to your collection."
        }
    }
}
