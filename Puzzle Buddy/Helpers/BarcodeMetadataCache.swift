//
//  BarcodeMetadataCache.swift
//  Puzzle Buddy
//
//  On-device barcode → puzzle metadata. Free alternative to paid UPC APIs.
//

import Foundation

private struct CachedBarcodeEntry: Codable, Equatable {
    var title: String?
    var brand: String?
    var pieces: Int?
}

enum BarcodeMetadataCache {
    private static let storageKey = "PuzzleBuddy.BarcodeMetadataCache"

    static func store(from puzzle: Puzzle) {
        guard let normalized = BarcodeNormalizer.normalize(puzzle.barcode) else { return }

        var cache = loadCache()
        cache[normalized] = CachedBarcodeEntry(
            title: BarcodeTitleParser.cleanedTitle(puzzle.name),
            brand: BarcodeTitleParser.cleanedTitle(puzzle.source),
            pieces: puzzle.pieces
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
                pieces: puzzle.pieces
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
            imageURL: nil,
            source: "local_cache"
        )
    }

    /// Persists a successful online lookup so repeat scans avoid network calls.
    static func storeLookup(_ metadata: BarcodeProductMetadata, for barcode: String) {
        guard metadata.source == "upcitemdb" else { return }
        guard metadata.suggestedName != nil || metadata.brand != nil else { return }
        guard let normalized = BarcodeNormalizer.normalize(barcode) else { return }

        var cache = loadCache()
        cache[normalized] = CachedBarcodeEntry(
            title: metadata.title,
            brand: metadata.brand,
            pieces: metadata.suggestedPieces
        )
        saveCache(cache)
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
