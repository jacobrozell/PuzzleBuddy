//
//  PuzzleStoreError.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleStoreError: LocalizedError {
    case duplicateBarcode(existingPuzzleName: String, barcode: String)
    case recordNotFound
    case completionNotFound
    case statusRequiredAfterRemovingLastCompletion
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .duplicateBarcode(let existingPuzzleName, let barcode):
            return "Another puzzle (\(existingPuzzleName)) already uses barcode \(barcode)."
        case .recordNotFound:
            return "That puzzle is no longer in your collection."
        case .completionNotFound:
            return "That completion log is no longer available."
        case .statusRequiredAfterRemovingLastCompletion:
            return "Choose a status after removing the last completion."
        case .saveFailed:
            return "Could not save changes to your collection."
        }
    }
}
