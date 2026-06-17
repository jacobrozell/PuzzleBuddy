//
//  BarcodeMetadataCacheTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class BarcodeMetadataCacheTests: XCTestCase {
    override func setUp() {
        super.setUp()
        BarcodeMetadataCache.resetForTesting()
    }

    func testStoresAndRetrievesMetadata() {
        var puzzle = Puzzle.fixture(name: "Winter Lights 1000 Piece Puzzle", pieces: 1000)
        puzzle.barcode = "012345678905"
        puzzle.source = "Galison"

        BarcodeMetadataCache.store(from: puzzle)

        let metadata = BarcodeMetadataCache.metadata(for: "012345678905")
        XCTAssertEqual(metadata?.suggestedName, "Winter Lights 1000 Piece Puzzle")
        XCTAssertEqual(metadata?.brand, "Galison")
        XCTAssertEqual(metadata?.suggestedPieces, 1000)
        XCTAssertEqual(metadata?.source, "local_cache")
    }

    func testWarmCacheLoadsFromPuzzles() {
        var puzzle = Puzzle.fixture(name: "Harbor Lights", pieces: 750)
        puzzle.barcode = "123456789012"

        BarcodeMetadataCache.warmCache(from: [puzzle])

        XCTAssertNotNil(BarcodeMetadataCache.metadata(for: "123456789012"))
    }

    func testStoreLookupPersistsOnlineResults() {
        let metadata = BarcodeProductMetadata.fromLookup(
            title: "Ravensburger Paris 1000 Piece Puzzle",
            brand: "Ravensburger",
            imageURL: nil
        )

        BarcodeMetadataCache.storeLookup(metadata, for: "4005556162980")

        let cached = BarcodeMetadataCache.metadata(for: "4005556162980")
        XCTAssertEqual(cached?.suggestedName, "Ravensburger Paris 1000 Piece Puzzle")
        XCTAssertEqual(cached?.brand, "Ravensburger")
        XCTAssertEqual(cached?.source, "local_cache")
    }

    func testStoreLookupIgnoresEmptyMetadata() {
        let metadata = BarcodeProductMetadata(
            title: nil,
            brand: nil,
            pieces: nil,
            imageURL: nil,
            source: "upcitemdb"
        )

        BarcodeMetadataCache.storeLookup(metadata, for: "4005556162980")

        XCTAssertNil(BarcodeMetadataCache.metadata(for: "4005556162980"))
    }
}
