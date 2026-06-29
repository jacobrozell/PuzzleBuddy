//
//  BarcodeMetadataCache.swift
//  Puzzle Buddy
//
//  On-device barcode → puzzle metadata from puzzles you have already saved.
//

import Foundation

private struct CachedBarcodeEntry: Codable, Equatable {
    var title: String?
    var brand: String?
    var pieces: Int?
    var sourcePuzzleID: UUID?
    var sourcePuzzleName: String?
}

enum BarcodeMetadataCache {
    private static let storageKey = "PuzzleBuddy.BarcodeMetadataCache"

    static func store(from puzzle: Puzzle) {
        guard let normalized = BarcodeNormalizer.normalize(puzzle.barcode) else { return }

        var cache = loadCache()
        cache[normalized] = CachedBarcodeEntry(
            title: BarcodeTitleParser.cleanedTitle(puzzle.name),
            brand: BarcodeTitleParser.cleanedTitle(puzzle.source),
            pieces: puzzle.pieces,
            sourcePuzzleID: puzzle.id,
            sourcePuzzleName: BarcodeTitleParser.cleanedTitle(puzzle.name)
        )
        saveCache(cache)
    }

    static func warmCache(from puzzles: [Puzzle]) {
        var cache = loadCache()
        for puzzle in puzzles {
            guard let normalized = BarcodeNormalizer.normalize(puzzle.barcode) else { continue }
            cache[normalized] = CachedBarcodeEntry(
                title: BarcodeTitleParser.cleanedTitle(puzzle.name),
                brand: BarcodeTitleParser.cleanedTitle(puzzle.source),
                pieces: puzzle.pieces,
                sourcePuzzleID: puzzle.id,
                sourcePuzzleName: BarcodeTitleParser.cleanedTitle(puzzle.name)
            )
        }
        saveCache(cache)
    }

    static func metadata(for barcode: String) -> BarcodeProductMetadata? {
        guard let normalized = BarcodeNormalizer.normalize(barcode),
              let entry = loadCache()[normalized] else {
            return nil
        }

        return BarcodeProductMetadata(
            title: entry.title,
            brand: entry.brand,
            pieces: entry.pieces,
            sourcePuzzleID: entry.sourcePuzzleID,
            sourcePuzzleName: entry.sourcePuzzleName
        )
    }

    #if DEBUG
    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    #endif

    private static func loadCache() -> [String: CachedBarcodeEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let cache = try? JSONDecoder().decode([String: CachedBarcodeEntry].self, from: data) else {
            return [:]
        }
        return cache
    }

    private static func saveCache(_ cache: [String: CachedBarcodeEntry]) {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
