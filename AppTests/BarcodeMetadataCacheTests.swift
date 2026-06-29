//
//  BarcodeMetadataCacheTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class BarcodeMetadataCacheTests: XCTestCase {
    override func setUp() {
        super.setUp()
        BarcodeMetadataCache.resetForTesting()
    }

    func testStoresAndRetrievesMetadata() {
        let puzzle = Puzzle.fixture(name: "Winter Lights 1000 Piece Puzzle", pieces: 1000)
        puzzle.barcode = "012345678905"
        puzzle.source = "Galison"

        BarcodeMetadataCache.store(from: puzzle)

        let metadata = BarcodeMetadataCache.metadata(for: "012345678905")
        XCTAssertEqual(metadata?.suggestedName, "Winter Lights 1000 Piece Puzzle")
        XCTAssertEqual(metadata?.brand, "Galison")
        XCTAssertEqual(metadata?.suggestedPieces, 1000)
        XCTAssertEqual(metadata?.sourcePuzzleName, "Winter Lights 1000 Piece Puzzle")
        XCTAssertEqual(metadata?.sourcePuzzleID, puzzle.id)
    }

    func testWarmCacheLoadsFromPuzzles() {
        let puzzle = Puzzle.fixture(name: "Harbor Lights", pieces: 750)
        puzzle.barcode = "123456789012"

        BarcodeMetadataCache.warmCache(from: [puzzle])

        XCTAssertNotNil(BarcodeMetadataCache.metadata(for: "123456789012"))
    }

    func testPersistenceRoundTripThroughUserDefaults() {
        BarcodeMetadataCache.resetForTesting()
        let puzzle = Puzzle.fixture(name: "Persisted", pieces: 1000)
        puzzle.barcode = "4005556197523"
        puzzle.source = "Ravensburger"

        BarcodeMetadataCache.store(from: puzzle)

        let metadata = BarcodeMetadataCache.metadata(for: "4005556197523")
        XCTAssertEqual(metadata?.brand, "Ravensburger")
        XCTAssertEqual(metadata?.suggestedPieces, 1000)
    }

    func testCorruptCacheReturnsNil() {
        BarcodeMetadataCache.resetForTesting()
        UserDefaults.standard.set(Data("not-json".utf8), forKey: "PuzzleBuddy.BarcodeMetadataCache")
        XCTAssertNil(BarcodeMetadataCache.metadata(for: "012345678905"))
    }
}
