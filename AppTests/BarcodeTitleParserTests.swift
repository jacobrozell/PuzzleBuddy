//
//  BarcodeTitleParserTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class BarcodeTitleParserTests: XCTestCase {
    func testExtractsPieceCountFromTitle() {
        XCTAssertEqual(
            BarcodeTitleParser.pieces(from: "Mountain Sunset Jigsaw Puzzle 1000 Pieces"),
            1000
        )
        XCTAssertEqual(
            BarcodeTitleParser.pieces(from: "Cabin 500 pc puzzle"),
            500
        )
    }

    func testReturnsNilWhenNoPieceCount() {
        XCTAssertNil(BarcodeTitleParser.pieces(from: "Mystery puzzle box"))
    }

    func testStripsTrailingJigsawJunkFromTitle() {
        XCTAssertEqual(
            BarcodeTitleParser.cleanedTitle("Mountain Sunset - Jigsaw Puzzle"),
            "Mountain Sunset"
        )
    }
}
