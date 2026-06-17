//
//  PuzzleDuplicateCheckerTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class PuzzleDuplicateCheckerTests: XCTestCase {
    func testFindsMatchingBarcode() {
        let existing = Puzzle.fixture(name: "Harbor", pieces: 500)
        existing.barcode = "012345678905"

        let match = PuzzleDuplicateChecker.findDuplicate(
            barcode: "0123-4567-8905",
            excludingID: nil,
            in: [existing]
        )

        XCTAssertEqual(match?.name, "Harbor")
    }

    func testExcludesSelfWhenEditing() {
        let existing = Puzzle.fixture(name: "Harbor", pieces: 500)
        existing.barcode = "012345678905"

        let match = PuzzleDuplicateChecker.findDuplicate(
            barcode: "012345678905",
            excludingID: existing.id,
            in: [existing]
        )

        XCTAssertNil(match)
    }
}
