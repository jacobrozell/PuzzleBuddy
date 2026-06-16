//
//  AccessibilityLabelTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class AccessibilityLabelTests: XCTestCase {
    func testAccessibilityIdentifierContract() {
        XCTAssertFalse(A11yID.loginSubmitButton.isEmpty)
        XCTAssertFalse(A11yID.addPuzzleButton.isEmpty)
        XCTAssertFalse(A11yID.puzzleList.isEmpty)
        XCTAssertTrue(A11yID.loginEmailField.hasPrefix("login_"))
        XCTAssertFalse(A11yID.puzzleFormSubmitButton.isEmpty)
        XCTAssertFalse(A11yID.puzzleFormNameField.isEmpty)
        XCTAssertFalse(A11yID.puzzleDetailEditButton.isEmpty)
    }

    func testPuzzleRatingAccessibilityDescription() {
        XCTAssertEqual(Puzzle.Rating.four.rawValue, 4.0)
        XCTAssertEqual(Puzzle.Rating.fourHalf.rawValue, 4.5)
    }
}
