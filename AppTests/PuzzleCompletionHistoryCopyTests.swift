//
//  PuzzleCompletionHistoryCopyTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class PuzzleCompletionHistoryCopyTests: XCTestCase {
    func testSwipeActionsAvailableWhenHistoryExists() {
        XCTAssertTrue(PuzzleCompletionHistoryCopy.supportsSwipeActions(completionCount: 1))
        XCTAssertTrue(PuzzleCompletionHistoryCopy.supportsSwipeActions(completionCount: 3))
        XCTAssertFalse(PuzzleCompletionHistoryCopy.supportsSwipeActions(completionCount: 0))
    }

    func testSwipeLabelsAreShortAndDestructive() {
        XCTAssertEqual(PuzzleCompletionHistoryCopy.swipeRemoveTitle, "Remove")
        XCTAssertEqual(PuzzleCompletionHistoryCopy.swipeEditTitle, "Edit")
        XCTAssertEqual(PuzzleCompletionHistoryCopy.deleteDialogTitle, "Remove completion?")
    }

    func testDeleteMessageForLastCompletionOmitsOtherFinishesCopy() {
        let date = Date(timeIntervalSince1970: 1_704_067_200)
        let message = PuzzleCompletionHistoryCopy.deleteDialogMessage(
            completionNumber: 1,
            completedAt: date,
            remainingCount: 1
        )
        XCTAssertTrue(message.contains("finish log"))
        XCTAssertFalse(message.contains("Other finishes"))
    }

    func testDeleteMessageForOneOfManyKeepsOtherFinishes() {
        let date = Date(timeIntervalSince1970: 1_704_067_200)
        let message = PuzzleCompletionHistoryCopy.deleteDialogMessage(
            completionNumber: 2,
            completedAt: date,
            remainingCount: 3
        )
        XCTAssertTrue(message.contains("#2"))
        XCTAssertTrue(message.contains("Other finishes stay in your history."))
    }
}
