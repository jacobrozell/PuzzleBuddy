//
//  PuzzleCollectionExporter.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleCollectionExportFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case csv = "CSV"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        }
    }

    var contentType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        }
    }
}

struct PuzzleExportRecord: Codable, Equatable {
    let id: String
    let name: String
    let pieces: Int?
    let status: String
    let rating: Double
    let difficulty: String
    let estimatedTimeHours: Int?
    let estimatedTimeMinutes: Int?
    let completionDate: Date
    let notes: String?
    let source: String?
    let progressPercent: Int
    let barcode: String?
    let tags: [String]
    let hasMissingPieces: Bool
    let hasImage: Bool
}

enum PuzzleCollectionExporter {
    static func exportRecords(from puzzles: [Puzzle]) -> [PuzzleExportRecord] {
        puzzles.map(exportRecord(from:))
    }

    static func jsonData(from puzzles: [Puzzle]) throws -> Data {
        let payload = ExportPayload(
            exportedAt: Date(),
            appVersion: Puzzle_BuddyApp.version,
            puzzleCount: puzzles.count,
            puzzles: exportRecords(from: puzzles)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    static func csvData(from puzzles: [Puzzle]) throws -> Data {
        try IPDbCSVFormat.csvData(from: puzzles)
    }

    static func writeTemporaryFile(
        from puzzles: [Puzzle],
        format: PuzzleCollectionExportFormat
    ) throws -> URL {
        let data: Data
        switch format {
        case .json:
            data = try jsonData(from: puzzles)
        case .csv:
            data = try csvData(from: puzzles)
        }

        let prefix = format == .csv ? "puzzle-buddy-ipdb-export" : "puzzle-buddy-export"
        let fileName = "\(prefix)-\(exportStamp()).\(format.fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func exportRecord(from puzzle: Puzzle) -> PuzzleExportRecord {
        PuzzleExportRecord(
            id: puzzle.id.uuidString,
            name: puzzle.name,
            pieces: puzzle.pieces,
            status: puzzle.status.rawValue,
            rating: puzzle.rating.rawValue,
            difficulty: puzzle.difficulty.rawValue,
            estimatedTimeHours: puzzle.estimatedTimeSpent?.hours,
            estimatedTimeMinutes: puzzle.estimatedTimeSpent?.minutes,
            completionDate: puzzle.completionDate,
            notes: puzzle.notes,
            source: puzzle.source,
            progressPercent: puzzle.progressPercent,
            barcode: puzzle.barcode,
            tags: puzzle.tags,
            hasMissingPieces: puzzle.hasMissingPieces,
            hasImage: puzzle.image != nil
        )
    }

    private static func exportStamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    private struct ExportPayload: Codable {
        let exportedAt: Date
        let appVersion: String
        let puzzleCount: Int
        let puzzles: [PuzzleExportRecord]
    }
}

enum PuzzleCollectionExportError: LocalizedError {
    case encodingFailed
    case emptyCollection

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Could not create the export file. Try again."
        case .emptyCollection:
            return "Add at least one puzzle before exporting."
        }
    }
}
