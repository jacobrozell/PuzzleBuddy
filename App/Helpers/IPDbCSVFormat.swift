//
//  IPDbCSVFormat.swift
//  Puzzle Buddy
//
//  Shared column layout for IPDb-compatible CSV import and export.
//

import Foundation

enum IPDbCSVFormat {
    static let columnHeaders = [
        "Title",
        "Brand",
        "Piece Count",
        "Barcode",
        "Folder",
        "Rating",
        "Difficulty",
        "Completion Date",
        "Notes",
        "Progress Percent",
        "Manufacturer ID"
    ]

    static func csvData(from puzzles: [Puzzle]) throws -> Data {
        var rows = [columnHeaders.joined(separator: ",")]
        for puzzle in puzzles {
            rows.append(rowValues(from: puzzle).map(csvField).joined(separator: ","))
        }

        guard let data = rows.joined(separator: "\n").data(using: .utf8) else {
            throw PuzzleCollectionExportError.encodingFailed
        }
        return data
    }

    static func rowValues(from puzzle: Puzzle) -> [String] {
        let (notes, manufacturerID) = splitManufacturerID(from: puzzle.notes)
        return [
            puzzle.name,
            puzzle.source ?? "",
            puzzle.pieces.map(String.init) ?? "",
            puzzle.barcode ?? "",
            folderValue(for: puzzle.status),
            puzzle.rating == .none ? "" : String(puzzle.rating.rawValue),
            puzzle.difficulty == .none ? "" : puzzle.difficulty.rawValue,
            completionDateValue(for: puzzle),
            notes ?? "",
            progressValue(for: puzzle),
            manufacturerID ?? ""
        ]
    }

    static func folderValue(for status: Puzzle.Status) -> String {
        switch status {
        case .wishlist:
            return "Wishlist"
        case .todo:
            return "To-Do"
        case .inProgress:
            return "In-Progress"
        case .completed:
            return "Completed"
        case .abandoned:
            return "Abandoned"
        }
    }

    static func splitManufacturerID(from notes: String?) -> (notes: String?, manufacturerID: String?) {
        guard let notes, !notes.isEmpty else { return (nil, nil) }

        let prefix = "Manufacturer ID: "
        var manufacturerID: String?
        let remainingLines = notes
            .components(separatedBy: "\n")
            .filter { line in
                guard line.hasPrefix(prefix) else { return true }
                manufacturerID = String(line.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return false
            }

        let remaining = remainingLines
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (remaining.isEmpty ? nil : remaining, manufacturerID)
    }

    private static func completionDateValue(for puzzle: Puzzle) -> String {
        guard puzzle.status == .completed else { return "" }
        return completionDateFormatter.string(from: puzzle.completionDate)
    }

    private static func progressValue(for puzzle: Puzzle) -> String {
        let progress = PuzzleProgressSemantics.clamped(puzzle.progressPercent)
        guard progress > 0 else { return "" }
        return String(progress)
    }

    private static let completionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func csvField(_ value: String) -> String {
        let needsQuoting = value.contains(",")
            || value.contains("\"")
            || value.contains("\n")
            || value.contains("\r")
        guard needsQuoting else { return value }

        let escaped = value
            .replacingOccurrences(of: "\"", with: "\"\"")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        return "\"\(escaped)\""
    }
}
