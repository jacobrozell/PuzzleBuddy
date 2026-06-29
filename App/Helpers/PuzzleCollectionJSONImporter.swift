//
//  PuzzleCollectionJSONImporter.swift
//  Puzzle Buddy
//
//  Restores Puzzle Buddy JSON backups. Missing optional fields get safe defaults.
//

import Foundation
import UIKit

enum PuzzleBackupImportPolicy: Equatable {
    /// Skip puzzles whose UUID already exists in the collection.
    case mergeSkipExistingIDs
    /// Delete all local puzzles, then restore the backup.
    case replaceAll
}

enum PuzzleCollectionJSONImportError: LocalizedError {
    case emptyFile
    case invalidFormat
    case noRestorablePuzzles
    case unsupportedFormatVersion(Int)

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The backup file looks empty. Choose a Puzzle Buddy JSON export and try again."
        case .invalidFormat:
            return "Could not read this backup. Export a fresh JSON file from Settings and try again."
        case .noRestorablePuzzles:
            return "No puzzles were found in this backup."
        case .unsupportedFormatVersion(let version):
            return "This backup requires a newer version of Puzzle Buddy (format v\(version)). Update the app and try again."
        }
    }
}

enum PuzzleCollectionJSONImporter {
    struct ParseResult {
        let puzzles: [Puzzle]
        let skippedInvalid: Int
        let totalRecords: Int
    }

    static func parse(from data: Data) throws -> ParseResult {
        guard !data.isEmpty else {
            throw PuzzleCollectionJSONImportError.emptyFile
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let payload: PuzzleBackupImportPayload
        do {
            payload = try decoder.decode(PuzzleBackupImportPayload.self, from: data)
        } catch {
            throw PuzzleCollectionJSONImportError.invalidFormat
        }

        let formatVersion = payload.resolvedFormatVersion
        if formatVersion > PuzzleCollectionBackupFormat.currentVersion {
            throw PuzzleCollectionJSONImportError.unsupportedFormatVersion(formatVersion)
        }

        var skippedInvalid = 0
        let restored = payload.puzzles.compactMap { record -> Puzzle? in
            guard let puzzle = PuzzleBackupNormalizer.puzzle(from: record) else {
                skippedInvalid += 1
                return nil
            }
            return puzzle
        }

        guard !restored.isEmpty else {
            throw PuzzleCollectionJSONImportError.noRestorablePuzzles
        }

        return ParseResult(
            puzzles: restored,
            skippedInvalid: skippedInvalid,
            totalRecords: payload.puzzles.count
        )
    }

    static func puzzles(from data: Data) throws -> [Puzzle] {
        try parse(from: data).puzzles
    }
}

// MARK: - Decoding (tolerant — missing keys are OK)

private struct PuzzleBackupImportPayload: Decodable {
    let backupFormatVersion: Int?
    let exportedAt: Date?
    let appVersion: String?
    let puzzleCount: Int?
    let puzzles: [PuzzleBackupImportRecord]

    var resolvedFormatVersion: Int {
        backupFormatVersion ?? PuzzleCollectionBackupFormat.currentVersion
    }
}

private struct PuzzleBackupImportRecord: Decodable {
    let id: String?
    let name: String?
    let pieces: Int?
    let status: String?
    let rating: Double?
    let difficulty: String?
    let estimatedTimeHours: Int?
    let estimatedTimeMinutes: Int?
    let completionDate: Date?
    let startDate: Date?
    let notes: String?
    let source: String?
    let purchaseLocation: String?
    let purchasePrice: Double?
    let purchaseCurrencyCode: String?
    let releaseYear: Int?
    let puzzleType: String?
    let material: String?
    let disposition: String?
    let puzzleShape: String?
    let cutType: String?
    let dimensionsText: String?
    let progressPercent: Int?
    let timesCompleted: Int?
    let barcode: String?
    let tags: [String]?
    let hasMissingPieces: Bool?
    let hasImage: Bool?
    let photoCount: Int?
    let photos: [PuzzleExportPhotoRecord]?
    let completions: [PuzzleBackupImportCompletionRecord]?
    let isDemo: Bool?
}

private struct PuzzleBackupImportCompletionRecord: Decodable {
    let id: String?
    let completionNumber: Int?
    let startedAt: Date?
    let completedAt: Date?
    let timeSpentHours: Int?
    let timeSpentMinutes: Int?
    let rating: Double?
}

// MARK: - Normalization

private enum PuzzleBackupNormalizer {
    static func puzzle(from record: PuzzleBackupImportRecord) -> Puzzle? {
        let trimmedName = record.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedName.isEmpty else { return nil }

        let status = parseStatus(record.status)
        var puzzle = Puzzle(
            name: String(trimmedName.prefix(200)),
            pieces: positivePieces(record.pieces),
            rating: parseRating(record.rating),
            difficulty: parseDifficulty(record.difficulty),
            estimatedTimeSpent: parseEstimatedTime(hours: record.estimatedTimeHours, minutes: record.estimatedTimeMinutes),
            completionDate: record.completionDate ?? Date(),
            status: status,
            startDate: record.startDate,
            hasMissingPieces: record.hasMissingPieces ?? false,
            notes: optionalString(record.notes, maxLength: 2_000),
            source: optionalString(record.source, maxLength: 200),
            purchaseLocation: optionalString(record.purchaseLocation, maxLength: 200),
            releaseYear: validReleaseYear(record.releaseYear),
            puzzleType: parsePuzzleType(record.puzzleType),
            material: parseMaterial(record.material),
            disposition: parseDisposition(record.disposition),
            progressPercent: parseProgress(record.progressPercent, status: status),
            purchasePrice: nonNegativePrice(record.purchasePrice),
            purchaseCurrencyCode: optionalString(record.purchaseCurrencyCode, maxLength: 8),
            puzzleShape: parsePuzzleShape(record.puzzleShape),
            cutType: parseCutType(record.cutType),
            dimensionsText: optionalString(record.dimensionsText, maxLength: 80),
            timesCompleted: max(record.timesCompleted ?? 0, 0),
            photos: parsePhotos(record.photos),
            completions: parseCompletions(record.completions),
            isDemo: record.isDemo ?? false,
            barcode: BarcodeNormalizer.normalize(record.barcode),
            tags: PuzzleTagSemantics.sanitizedTags(record.tags ?? [])
        )

        if let idString = record.id, let uuid = UUID(uuidString: idString) {
            puzzle.id = uuid
        }

        return finalize(puzzle)
    }

    static func finalize(_ puzzle: Puzzle) -> Puzzle {
        var puzzle = puzzle

        if puzzle.progressPercent == 0 {
            puzzle.progressPercent = PuzzleProgressSemantics.progress(for: puzzle.status, current: 0)
        }

        if puzzle.timesCompleted < puzzle.completions.count {
            puzzle.timesCompleted = puzzle.completions.count
        }

        if puzzle.status == .completed && puzzle.completions.isEmpty {
            let inferredCount = max(puzzle.timesCompleted, 1)
            puzzle.timesCompleted = inferredCount
            puzzle.completions = (1...inferredCount).map {
                PuzzleCompletionSemantics.makeCompletion(from: puzzle, number: $0)
            }
        }

        puzzle.prepareForPersistence()
        return puzzle
    }

    private static func parsePhotos(_ records: [PuzzleExportPhotoRecord]?) -> [PuzzlePhoto] {
        guard let records else { return [] }

        var decoded: [PuzzlePhoto] = []
        for record in records {
            guard let base64 = record.imageDataBase64,
                  let data = Data(base64Encoded: base64),
                  let image = UIImage(data: data) else {
                continue
            }
            let id = UUID(uuidString: record.id) ?? UUID()
            decoded.append(
                PuzzlePhoto(
                    id: id,
                    sortOrder: record.sortOrder,
                    image: image,
                    createdAt: record.createdAt ?? Date()
                )
            )
        }

        return PuzzlePhotoSemantics.sortedAndNormalized(
            Array(decoded.prefix(PuzzlePhotoLimits.maxCount))
        )
    }

    private static func parseCompletions(_ records: [PuzzleBackupImportCompletionRecord]?) -> [PuzzleCompletion] {
        guard let records else { return [] }

        return records.compactMap { record in
            guard let completionNumber = record.completionNumber, completionNumber > 0 else { return nil }
            return PuzzleCompletion(
                id: record.id.flatMap(UUID.init(uuidString:)) ?? UUID(),
                completionNumber: completionNumber,
                startedAt: record.startedAt,
                completedAt: record.completedAt ?? Date(),
                timeSpentHours: record.timeSpentHours,
                timeSpentMinutes: record.timeSpentMinutes,
                rating: record.rating
            )
        }
        .sorted { $0.completionNumber < $1.completionNumber }
    }

    private static func parseStatus(_ raw: String?) -> Puzzle.Status {
        guard let raw else { return .todo }
        return Puzzle.Status(rawValue: raw) ?? .todo
    }

    private static func parseRating(_ raw: Double?) -> Puzzle.Rating {
        guard let raw else { return .none }
        let snapped = (raw * 2).rounded() / 2
        return Puzzle.Rating.allCases.min(by: { abs($0.rawValue - snapped) < abs($1.rawValue - snapped) }) ?? .none
    }

    private static func parseDifficulty(_ raw: String?) -> Puzzle.Difficulty {
        guard let raw, let match = Puzzle.Difficulty(rawValue: raw) else { return .none }
        return match
    }

    private static func parsePuzzleType(_ raw: String?) -> PuzzleType {
        guard let raw, !raw.isEmpty else { return .none }
        if let match = PuzzleType.allCases.first(where: { $0 != .none && $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame }) {
            return match
        }
        return .other
    }

    private static func parseMaterial(_ raw: String?) -> PuzzleMaterial {
        guard let raw, !raw.isEmpty else { return .none }
        if let match = PuzzleMaterial.allCases.first(where: { $0 != .none && $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame }) {
            return match
        }
        return .other
    }

    private static func parseDisposition(_ raw: String?) -> PuzzleDisposition {
        guard let raw, !raw.isEmpty else { return .none }
        return PuzzleDisposition.allCases.first(where: {
            $0 != .none && $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame
        }) ?? .none
    }

    private static func parsePuzzleShape(_ raw: String?) -> PuzzleShape {
        guard let raw, let shape = PuzzleShape(rawValue: raw) else { return .none }
        return shape
    }

    private static func parseCutType(_ raw: String?) -> PuzzleCutType {
        guard let raw, let cut = PuzzleCutType(rawValue: raw) else { return .none }
        return cut
    }

    private static func parseProgress(_ raw: Int?, status: Puzzle.Status) -> Int {
        if let raw {
            return PuzzleProgressSemantics.clamped(raw)
        }
        return PuzzleProgressSemantics.progress(for: status, current: 0)
    }

    private static func parseEstimatedTime(hours: Int?, minutes: Int?) -> Puzzle.PuzzleTime? {
        guard hours != nil || minutes != nil else { return nil }
        return Puzzle.PuzzleTime(hours: hours, minutes: minutes)
    }

    private static func positivePieces(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return value
    }

    private static func nonNegativePrice(_ value: Double?) -> Double? {
        guard let value, value >= 0 else { return nil }
        return min(value, 999_999.99)
    }

    private static func validReleaseYear(_ value: Int?) -> Int? {
        guard let value, (1900...2100).contains(value) else { return nil }
        return value
    }

    private static func optionalString(_ value: String?, maxLength: Int) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxLength))
    }
}
