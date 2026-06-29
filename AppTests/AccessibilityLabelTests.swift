//
//  AccessibilityLabelTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class AccessibilityLabelTests: XCTestCase {
    func testAccessibilityIdentifierContract() {
        XCTAssertFalse(A11yID.addPuzzleButton.isEmpty)
        XCTAssertFalse(A11yID.puzzleList.isEmpty)
        XCTAssertFalse(A11yID.puzzleFormSubmitButton.isEmpty)
        XCTAssertFalse(A11yID.puzzleFormNameField.isEmpty)
        XCTAssertFalse(A11yID.puzzleFormRatingControl.isEmpty)
        XCTAssertFalse(A11yID.puzzleDetailEditButton.isEmpty)
        XCTAssertFalse(A11yID.puzzleDetailRedoButton.isEmpty)
        XCTAssertFalse(A11yID.puzzleFormChoosePhotoButton.isEmpty)
        XCTAssertFalse(A11yID.puzzleFormTakePhotoButton.isEmpty)
        XCTAssertFalse(A11yID.collectionStatsScreen.isEmpty)
        XCTAssertFalse(A11yID.collectionStatsCompletedCard.isEmpty)
        XCTAssertFalse(A11yID.statsTab.isEmpty)
        XCTAssertFalse(A11yID.puzzleDetailPaceRow.isEmpty)
        XCTAssertFalse(A11yID.puzzleDetailHoursPer1000Row.isEmpty)
        XCTAssertFalse(A11yID.puzzleDetailProgress.isEmpty)
        XCTAssertFalse(A11yID.scanBarcodeButton.isEmpty)
        XCTAssertFalse(A11yID.pickNextButton.isEmpty)
        XCTAssertFalse(A11yID.pickNextSpinButton.isEmpty)
        XCTAssertFalse(A11yID.puzzleFormScanBarcodeButton.isEmpty)
        XCTAssertFalse(A11yID.puzzleDetailBarcodeRow.isEmpty)
        XCTAssertFalse(A11yID.settingsBrandDisclaimerFooter.isEmpty)
        XCTAssertFalse(A11yID.ipdbImportSummarySheet.isEmpty)
        XCTAssertFalse(A11yID.ipdbImportDoneButton.isEmpty)
        XCTAssertFalse(A11yID.quickAddSimilarSection.isEmpty)
        XCTAssertFalse(A11yID.settingsImportIPDbButton.isEmpty)
        XCTAssertFalse(A11yID.settingsExportCollectionButton.isEmpty)
        XCTAssertFalse(A11yID.shoppingModeMatchCard.isEmpty)
        XCTAssertFalse(A11yID.puzzleListStatusFilter.isEmpty)
        XCTAssertFalse(A11yID.puzzleListEmptyState.isEmpty)
        XCTAssertFalse(A11yID.puzzleListSortMenu.isEmpty)
        XCTAssertFalse(A11yID.puzzleListSearchField.isEmpty)
        XCTAssertFalse(A11yID.puzzleListClearFilters.isEmpty)
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
        XCTAssertEqual(Puzzle.Status.wishlist.accessibilityDescription, "Wishlist, not yet owned")
        XCTAssertEqual(Puzzle.Status.todo.accessibilityDescription, "To-Do, not started")
        XCTAssertEqual(Puzzle.Status.inProgress.accessibilityDescription, "In progress")
        XCTAssertEqual(Puzzle.Status.completed.accessibilityDescription, "Completed")
    }

    func testPuzzleDifficultyAccessibilityDescription() {
        XCTAssertEqual(Puzzle.Difficulty.none.accessibilityDescription, "No difficulty")
        XCTAssertEqual(Puzzle.Difficulty.three.accessibilityDescription, "Difficulty 3 out of 5")
    }
}
