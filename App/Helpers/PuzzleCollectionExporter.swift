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
    let startDate: Date?
    let notes: String?
    let source: String?
    let purchaseLocation: String?
    let purchasePrice: Double?
    let purchaseCurrencyCode: String?
    let releaseYear: Int?
    let puzzleType: String
    let material: String
    let disposition: String
    let puzzleShape: String
    let cutType: String
    let dimensionsText: String?
    let progressPercent: Int
    let timesCompleted: Int
    let barcode: String?
    let tags: [String]
    let hasMissingPieces: Bool
    let hasImage: Bool
    let photoCount: Int
    let photos: [PuzzleExportPhotoRecord]
    let completions: [PuzzleExportCompletionRecord]
}

struct PuzzleExportCompletionRecord: Codable, Equatable {
    let completionNumber: Int
    let startedAt: Date?
    let completedAt: Date
    let timeSpentHours: Int?
    let timeSpentMinutes: Int?
    let rating: Double?
}

enum PuzzleCollectionExporter {
    static func exportRecords(from puzzles: [Puzzle]) -> [PuzzleExportRecord] {
        puzzles.map(exportRecord(from:))
    }

    static func jsonData(from puzzles: [Puzzle]) throws -> Data {
        let payload = ExportPayload(
            backupFormatVersion: PuzzleCollectionBackupFormat.currentVersion,
            exportedAt: Date(),
            appVersion: PuzzleBuddyApp.version,
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
            startDate: puzzle.startDate,
            notes: puzzle.notes,
            source: puzzle.source,
            purchaseLocation: puzzle.purchaseLocation,
            purchasePrice: puzzle.purchasePrice,
            purchaseCurrencyCode: puzzle.purchaseCurrencyCode,
            releaseYear: puzzle.releaseYear,
            puzzleType: puzzle.puzzleType.rawValue,
            material: puzzle.material.rawValue,
            disposition: puzzle.disposition.rawValue,
            puzzleShape: puzzle.puzzleShape.rawValue,
            cutType: puzzle.cutType.rawValue,
            dimensionsText: puzzle.dimensionsText,
            progressPercent: puzzle.progressPercent,
            timesCompleted: puzzle.timesCompleted,
            barcode: puzzle.barcode,
            tags: puzzle.tags,
            hasMissingPieces: puzzle.hasMissingPieces,
            hasImage: puzzle.coverImage != nil,
            photoCount: puzzle.photos.filter { $0.image != nil }.count,
            photos: exportPhotos(from: puzzle.photos),
            completions: puzzle.completions.map {
                PuzzleExportCompletionRecord(
                    completionNumber: $0.completionNumber,
                    startedAt: $0.startedAt,
                    completedAt: $0.completedAt,
                    timeSpentHours: $0.timeSpentHours,
                    timeSpentMinutes: $0.timeSpentMinutes,
                    rating: $0.rating
                )
            }
        )
    }

    private static func exportPhotos(from photos: [PuzzlePhoto]) -> [PuzzleExportPhotoRecord] {
        PuzzlePhotoSemantics.sorted(photos).compactMap { photo in
            guard let jpeg = photo.image?.jpegData(compressionQuality: 0.30) else { return nil }
            return PuzzleExportPhotoRecord(
                id: photo.id.uuidString,
                sortOrder: photo.sortOrder,
                imageDataBase64: jpeg.base64EncodedString(),
                createdAt: photo.createdAt
            )
        }
    }

    private static func exportStamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    private struct ExportPayload: Codable {
        let backupFormatVersion: Int
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
