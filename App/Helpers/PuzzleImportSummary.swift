//
//  PuzzleImportSummary.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleImportSource: Equatable {
    case ipdbCSV
    case jsonBackup
}

struct PuzzleImportSummary: Equatable {
    var imported = 0
    var skippedDuplicates = 0
    var skippedInvalid = 0
    var skippedExisting = 0
    var errors: [String] = []
    var source: PuzzleImportSource = .ipdbCSV

    var hasErrors: Bool { !errors.isEmpty }

    var message: String {
        var parts: [String] = []
        if imported > 0 {
            parts.append("\(imported) puzzle\(imported == 1 ? "" : "s") imported")
        }
        if skippedExisting > 0 {
            parts.append("\(skippedExisting) already in collection")
        }
        if skippedDuplicates > 0 {
            parts.append("\(skippedDuplicates) duplicate\(skippedDuplicates == 1 ? "" : "s") skipped")
        }
        if skippedInvalid > 0 {
            let reason = source == .jsonBackup ? "invalid entries" : "rows skipped (missing name)"
            parts.append("\(skippedInvalid) \(reason)")
        }
        if parts.isEmpty {
            return source == .jsonBackup ? "No puzzles were restored." : "No puzzles were imported."
        }
        return parts.joined(separator: ". ") + "."
    }
}

extension PuzzleImportSummary: Identifiable {
    var id: String {
        "\(imported)-\(skippedDuplicates)-\(skippedInvalid)-\(skippedExisting)-\(errors.count)-\(source)"
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
