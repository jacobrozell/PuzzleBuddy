//
//  PuzzleMetadataEnumsTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class PuzzleMetadataEnumsTests: XCTestCase {
    func testPuzzleShapeSelectableCasesExcludeNone() {
        XCTAssertFalse(PuzzleShape.selectableCases.contains(.none))
        XCTAssertTrue(PuzzleShape.selectableCases.contains(.round))
    }

    func testPuzzleCutTypeAccessibilityDescription() {
        XCTAssertEqual(PuzzleCutType.grid.accessibilityDescription, "Cut type Grid")
        XCTAssertEqual(PuzzleCutType.none.accessibilityDescription, "No cut type")
    }

    func testPuzzleShapeRoundTripRawValue() {
        XCTAssertEqual(PuzzleShape(rawValue: PuzzleShape.irregular.rawValue), .irregular)
    }
}
