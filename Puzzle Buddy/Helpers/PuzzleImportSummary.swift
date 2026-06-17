//
//  PuzzleImportSummary.swift
//  Puzzle Buddy
//

import Foundation

struct PuzzleImportSummary: Equatable {
    var imported = 0
    var skippedDuplicates = 0
    var skippedInvalid = 0
    var errors: [String] = []

    var hasErrors: Bool { !errors.isEmpty }

    var message: String {
        var parts: [String] = []
        if imported > 0 {
            parts.append("\(imported) puzzle\(imported == 1 ? "" : "s") imported")
        }
        if skippedDuplicates > 0 {
            parts.append("\(skippedDuplicates) duplicate\(skippedDuplicates == 1 ? "" : "s") skipped")
        }
        if skippedInvalid > 0 {
            parts.append("\(skippedInvalid) row\(skippedInvalid == 1 ? "" : "s") skipped (missing name)")
        }
        if parts.isEmpty {
            return "No puzzles were imported."
        }
        return parts.joined(separator: ". ") + "."
    }
}

extension PuzzleImportSummary: Identifiable {
    var id: String {
        "\(imported)-\(skippedDuplicates)-\(skippedInvalid)-\(errors.count)"
    }
}

enum IPDbCSVImportError: LocalizedError {
    case emptyFile
    case missingTitleColumn
    case unreadableEncoding

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The file looks empty. Export a CSV from IPDb and try again."
        case .missingTitleColumn:
            return "Could not find a puzzle title column. IPDb exports should include Title or Name."
        case .unreadableEncoding:
            return "Could not read the file. Save the export as UTF-8 CSV and try again."
        }
    }
}
