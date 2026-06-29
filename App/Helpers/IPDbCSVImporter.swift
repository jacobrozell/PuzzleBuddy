//
//  IPDbCSVImporter.swift
//  Puzzle Buddy
//
//  Imports puzzle rows from IPDb CSV exports (user-provided file from Listview → Export → CSV).
//

import Foundation

enum IPDbCSVImporter {
    static func puzzles(from data: Data) throws -> [Puzzle] {
        guard let text = decodeText(from: data), !text.isEmpty else {
            throw IPDbCSVImportError.emptyFile
        }

        let (_, records) = CSVTable.parseDelimitedRows(text)
        guard !records.isEmpty else {
            throw IPDbCSVImportError.emptyFile
        }

        var puzzles: [Puzzle] = []
        for record in records {
            guard let puzzle = puzzle(from: record) else { continue }
            puzzles.append(puzzle)
        }

        guard !puzzles.isEmpty else {
            throw IPDbCSVImportError.missingTitleColumn
        }

        return puzzles
    }

    static func puzzle(from record: [String: String]) -> Puzzle? {
        let normalized = normalizeKeys(record)
        guard let name = firstValue(in: normalized, keys: titleKeys), !name.isEmpty else {
            return nil
        }

        let pieces = firstValue(in: normalized, keys: piecesKeys).flatMap(parsePieces)
        let brand = firstValue(in: normalized, keys: brandKeys)
        let barcode = firstValue(in: normalized, keys: barcodeKeys).flatMap {
            BarcodeNormalizer.normalize($0) ?? BarcodeNormalizer.optionalDigits(from: $0)
        }
        let notes = mergedNotes(from: normalized)
        let status = parseStatus(firstValue(in: normalized, keys: statusKeys))
        let progress = parseProgress(firstValue(in: normalized, keys: progressKeys))
            ?? PuzzleProgressSemantics.progress(for: status, current: 0)
        let rating = parseRating(firstValue(in: normalized, keys: ratingKeys))
        let difficulty = parseDifficulty(firstValue(in: normalized, keys: difficultyKeys))
        let completionDate = parseDate(firstValue(in: normalized, keys: completionDateKeys)) ?? Date()
        let purchaseLocation = firstValue(in: normalized, keys: purchaseLocationKeys)
        let releaseYear = firstValue(in: normalized, keys: releaseYearKeys).flatMap(parseReleaseYear)
        let puzzleType = parsePuzzleType(firstValue(in: normalized, keys: puzzleTypeKeys))
        let material = parseMaterial(firstValue(in: normalized, keys: materialKeys))
        let disposition = parseDisposition(firstValue(in: normalized, keys: dispositionKeys))

        let puzzle = Puzzle(
            name: String(name.prefix(200)),
            pieces: pieces,
            rating: rating,
            difficulty: difficulty,
            estimatedTimeSpent: nil,
            completionDate: completionDate,
            status: status,
            notes: notes,
            source: brand.map { String($0.prefix(200)) },
            purchaseLocation: purchaseLocation.map { String($0.prefix(200)) },
            releaseYear: releaseYear,
            puzzleType: puzzleType,
            material: material,
            disposition: disposition,
            progressPercent: progress,
            barcode: barcode
        )
        return puzzle
    }

    // MARK: - Column aliases (IPDb + common variants)

    private static let titleKeys = [
        "name", "title", "puzzle name", "puzzle title", "name title", "puzzle"
    ]
    private static let brandKeys = [
        "brand", "manufacturer", "source", "puzzle brand"
    ]
    private static let piecesKeys = [
        "pieces", "piece count", "piececount", "number of pieces", "of pieces", "pcs"
    ]
    private static let barcodeKeys = [
        "barcode", "upc", "ean", "barcode on the box", "bar code"
    ]
    private static let statusKeys = [
        "status", "folder", "collection status", "my status", "puzzle status"
    ]
    private static let progressKeys = [
        "progress", "progress percent", "percent complete", "% complete", "completion percent"
    ]
    private static let notesKeys = [
        "notes", "note", "comments", "private notes", "my notes"
    ]
    private static let ratingKeys = [
        "rating", "my rating", "user rating", "star rating"
    ]
    private static let difficultyKeys = [
        "difficulty", "my difficulty", "puzzle difficulty"
    ]
    private static let completionDateKeys = [
        "completion date", "completed date", "date completed", "finished date", "completiondate"
    ]
    private static let manufacturerIDKeys = [
        "manufacturer id", "manufacturer id reference", "sku", "product id", "reference number"
    ]
    private static let purchaseLocationKeys = [
        "purchase location", "store", "where bought", "shop", "retailer"
    ]
    private static let releaseYearKeys = [
        "year", "release year", "puzzle year", "copyright year"
    ]
    private static let puzzleTypeKeys = [
        "type", "puzzle type", "category", "theme"
    ]
    private static let materialKeys = [
        "material", "puzzle material"
    ]
    private static let dispositionKeys = [
        "disposition", "fate", "after complete", "after finishing"
    ]

    private static func normalizeKeys(_ record: [String: String]) -> [String: String] {
        var normalized: [String: String] = [:]
        for (key, value) in record {
            normalized[normalizeHeader(key)] = value
        }
        return normalized
    }

    private static func normalizeHeader(_ header: String) -> String {
        header
            .lowercased()
            .replacingOccurrences(of: "/", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstValue(in record: [String: String], keys: [String]) -> String? {
        for key in keys {
            if let value = record[key]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
                return value
            }
        }
        return nil
    }

    private static func mergedNotes(from record: [String: String]) -> String? {
        var parts: [String] = []
        if let notes = firstValue(in: record, keys: notesKeys) {
            parts.append(notes)
        }
        if let manufacturerID = firstValue(in: record, keys: manufacturerIDKeys) {
            parts.append("Manufacturer ID: \(manufacturerID)")
        }
        let merged = parts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !merged.isEmpty else { return nil }
        return String(merged.prefix(2_000))
    }

    private static func parsePieces(_ raw: String) -> Int? {
        let digits = raw.filter(\.isNumber)
        guard let value = Int(digits), value > 0 else { return nil }
        return value
    }


    private static func parseStatus(_ raw: String?) -> Puzzle.Status {
        guard let raw else { return .todo }
        let value = raw.lowercased()
        if value.contains("complete") || value.contains("finished") || value.contains("done") {
            return .completed
        }
        if value.contains("progress") || value.contains("started") || value.contains("working") {
            return .inProgress
        }
        if value.contains("wish") {
            return .wishlist
        }
        if value.contains("abandon") || value.contains("quit") || value.contains("stopped") {
            return .abandoned
        }
        if value.contains("to-do") || value.contains("todo") || value.contains("backlog") || value.contains("waiting") {
            return .todo
        }
        return .todo
    }

    private static func parseProgress(_ raw: String?) -> Int? {
        guard let raw, !raw.isEmpty else { return nil }
        let digits = raw.filter(\.isNumber)
        guard let value = Int(digits) else { return nil }
        return PuzzleProgressSemantics.clamped(value)
    }

    private static func parseRating(_ raw: String?) -> Puzzle.Rating {
        guard let raw, let value = Double(raw.filter { $0.isNumber || $0 == "." }) else {
            return .none
        }
        let snapped = (value * 2).rounded() / 2
        return Puzzle.Rating.allCases.min(by: { abs($0.rawValue - snapped) < abs($1.rawValue - snapped) }) ?? .none
    }

    private static func parseDifficulty(_ raw: String?) -> Puzzle.Difficulty {
        guard let raw, let digit = raw.first(where: \.isNumber), let value = Int(String(digit)), (1...5).contains(value) else {
            return .none
        }
        return Puzzle.Difficulty.allCases.first(where: { $0.rawValue == String(value) }) ?? .none
    }

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let formats = ["yyyy-MM-dd", "MM/dd/yyyy", "dd/MM/yyyy", "M/d/yyyy", "d/M/yyyy"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: raw) {
                return date
            }
        }
        return nil
    }

    private static func parseReleaseYear(_ raw: String) -> Int? {
        let digits = raw.filter(\.isNumber)
        guard let year = Int(digits), (1900...2100).contains(year) else { return nil }
        return year
    }

    private static func parsePuzzleType(_ raw: String?) -> PuzzleType {
        guard let raw, !raw.isEmpty else { return .none }
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = PuzzleType.allCases.first(where: {
            $0 != .none && $0.rawValue.caseInsensitiveCompare(normalized) == .orderedSame
        }) {
            return match
        }
        return .other
    }

    private static func parseMaterial(_ raw: String?) -> PuzzleMaterial {
        guard let raw, !raw.isEmpty else { return .none }
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = PuzzleMaterial.allCases.first(where: {
            $0 != .none && $0.rawValue.caseInsensitiveCompare(normalized) == .orderedSame
        }) {
            return match
        }
        return .other
    }

    private static func parseDisposition(_ raw: String?) -> PuzzleDisposition {
        guard let raw, !raw.isEmpty else { return .none }
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return PuzzleDisposition.allCases.first(where: {
            $0 != .none && $0.rawValue.caseInsensitiveCompare(normalized) == .orderedSame
        }) ?? .none
    }

    private static func decodeText(from data: Data) -> String? {
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        if let latin = String(data: data, encoding: .windowsCP1252) { return latin }
        return nil
    }
}
