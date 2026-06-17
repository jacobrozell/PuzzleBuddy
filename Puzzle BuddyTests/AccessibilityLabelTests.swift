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
        XCTAssertFalse(A11yID.puzzleFormRatingControl.isEmpty)
        XCTAssertFalse(A11yID.puzzleDetailEditButton.isEmpty)
        XCTAssertFalse(A11yID.collectionStatsScreen.isEmpty)
        XCTAssertFalse(A11yID.collectionStatsCompletedCard.isEmpty)
        XCTAssertFalse(A11yID.statsTab.isEmpty)
        XCTAssertFalse(A11yID.puzzleDetailPaceRow.isEmpty)
        XCTAssertFalse(A11yID.puzzleDetailHoursPer1000Row.isEmpty)
        XCTAssertFalse(A11yID.puzzleDetailProgress.isEmpty)
        XCTAssertFalse(A11yID.scanBarcodeButton.isEmpty)
        XCTAssertFalse(A11yID.barcodeScannerSheet.isEmpty)
        XCTAssertFalse(A11yID.puzzleListStatusFilter.isEmpty)
        XCTAssertFalse(A11yID.puzzleListEmptyState.isEmpty)
        XCTAssertFalse(A11yID.puzzleListSortMenu.isEmpty)
        XCTAssertFalse(A11yID.puzzleListSearchField.isEmpty)
        XCTAssertFalse(A11yID.puzzleCellRating.isEmpty)
        XCTAssertFalse(A11yID.settingsRemoveDemoButton.isEmpty)
        XCTAssertFalse(A11yID.puzzleShareButton.isEmpty)
        XCTAssertFalse(A11yID.puzzleCellProgress.isEmpty)
    }

    func testPuzzleRatingAccessibilityDescription() {
        XCTAssertEqual(Puzzle.Rating.four.rawValue, 4.0)
        XCTAssertEqual(Puzzle.Rating.fourHalf.rawValue, 4.5)
        XCTAssertEqual(Puzzle.Rating.four.accessibilityDescription, "Rating 4.0 out of 5")
        XCTAssertEqual(Puzzle.Rating.none.accessibilityDescription, "No rating")
    }

    func testPuzzleStatusAccessibilityDescription() {
        XCTAssertEqual(Puzzle.Status.todo.accessibilityDescription, "To-Do, not started")
        XCTAssertEqual(Puzzle.Status.inProgress.accessibilityDescription, "In progress")
        XCTAssertEqual(Puzzle.Status.completed.accessibilityDescription, "Completed")
    }

    func testPuzzleDifficultyAccessibilityDescription() {
        XCTAssertEqual(Puzzle.Difficulty.none.accessibilityDescription, "No difficulty")
        XCTAssertEqual(Puzzle.Difficulty.three.accessibilityDescription, "Difficulty 3 out of 5")
    }
}
