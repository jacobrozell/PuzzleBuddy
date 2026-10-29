//
//  CompletionUndoSemanticsTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class CompletionUndoSemanticsTests: XCTestCase {
    func testSnapshotIsActiveInsideWindow() {
        let recordedAt = Date(timeIntervalSince1970: 1_000)
        let snapshot = CompletionUndoSemantics.snapshot(
            puzzleID: UUID(),
            completionID: UUID(),
            previousStatus: .inProgress,
            previousProgressPercent: 45,
            recordedAt: recordedAt
        )

        XCTAssertTrue(snapshot.isActive(now: recordedAt.addingTimeInterval(60)))
        XCTAssertTrue(snapshot.isActive(now: recordedAt.addingTimeInterval(CompletionUndoSemantics.window)))
        XCTAssertFalse(snapshot.isActive(now: recordedAt.addingTimeInterval(CompletionUndoSemantics.window + 1)))
    }

    func testActiveSnapshotRequiresMatchingPuzzle() {
        let puzzleID = UUID()
        let snapshot = CompletionUndoSemantics.snapshot(
            puzzleID: puzzleID,
            completionID: UUID(),
            previousStatus: .todo,
            previousProgressPercent: 0
        )

        XCTAssertNotNil(CompletionUndoSemantics.activeSnapshot(snapshot, puzzleID: puzzleID))
        XCTAssertNil(CompletionUndoSemantics.activeSnapshot(snapshot, puzzleID: UUID()))
        XCTAssertNil(CompletionUndoSemantics.activeSnapshot(nil, puzzleID: puzzleID))
    }

    func testSnapshotClampsPreviousProgress() {
        let snapshot = CompletionUndoSemantics.snapshot(
            puzzleID: UUID(),
            completionID: UUID(),
            previousStatus: .inProgress,
            previousProgressPercent: 140
        )
        XCTAssertEqual(snapshot.previousProgressPercent, 100)
    }
}
