//
//  PuzzleSimilarMatchFinderTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class PuzzleSimilarMatchFinderTests: XCTestCase {
    func testFindsMatchByNameBrandAndPieces() {
        var existing = Puzzle.fixture(name: "Winter Lights", pieces: 1000)
        existing.source = "Galison"

        let matches = PuzzleSimilarMatchFinder.findSimilar(
            name: "Winter Lights",
            source: "Galison",
            pieces: 1000,
            barcode: "999999999999",
            excludingID: nil,
            in: [existing]
        )

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.id, existing.id)
    }

    func testSkipsExactBarcodeDuplicate() {
        var existing = Puzzle.fixture(name: "Winter Lights", pieces: 1000)
        existing.barcode = "012345678905"

        let matches = PuzzleSimilarMatchFinder.findSimilar(
            name: "Winter Lights",
            source: "Galison",
            pieces: 1000,
            barcode: "012345678905",
            excludingID: nil,
            in: [existing]
        )

        XCTAssertTrue(matches.isEmpty)
    }
}
