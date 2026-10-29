//
//  PuzzleTimerStoreTests.swift
//  Puzzle BuddyTests
//

import SwiftData
import XCTest
@testable import PuzzleBuddy

@MainActor
final class PuzzleTimerStoreTests: XCTestCase {
    private var container: ModelContainer!
    private var store: PuzzleStore!

    override func setUp() async throws {
        container = PuzzleModelContainer.makeInMemory()
        store = PuzzleStore(modelContext: container.mainContext)
    }

    func testStartPersistsAnchor() async throws {
        let id = try addInProgress("Anchor")
        let started = Date().addingTimeInterval(-600)
        try store.startTimer(id: id, now: started)

        XCTAssertEqual(puzzle(id).timerRunningSince, started)

        let reloaded = PuzzleStore(modelContext: container.mainContext)
        await reloaded.fetchPuzzles()
        let loaded = try XCTUnwrap(reloaded.puzzles.first { $0.id == id })
        XCTAssertEqual(loaded.timerRunningSince, started)
        XCTAssertEqual(loaded.timerAccumulatedSeconds, 0)
    }

    func testStartingSecondPuzzlePausesFirst() throws {
        let first = try addInProgress("First")
        let second = try addInProgress("Second")
        let start = Date().addingTimeInterval(-1_000)

        try store.startTimer(id: first, now: start)
        try store.startTimer(id: second, now: start.addingTimeInterval(300))

        XCTAssertNil(puzzle(first).timerRunningSince)
        XCTAssertEqual(puzzle(first).timerAccumulatedSeconds, 300)
        XCTAssertEqual(puzzle(second).timerRunningSince, start.addingTimeInterval(300))
    }

    func testPauseAndResumeAccumulate() throws {
        let id = try addInProgress("Resume")
        let start = Date().addingTimeInterval(-1_000)
        try store.startTimer(id: id, now: start)
        try store.pauseTimer(id: id, now: start.addingTimeInterval(120))
        try store.startTimer(id: id, now: start.addingTimeInterval(500))
        try store.pauseTimer(id: id, now: start.addingTimeInterval(530))

        XCTAssertEqual(puzzle(id).timerAccumulatedSeconds, 150)
        XCTAssertNil(puzzle(id).timerRunningSince)
    }

    func testStartIgnoredWhenNotInProgress() throws {
        try store.add(puzzle: Puzzle.fixture(name: "Shelf", pieces: 500))
        let id = try XCTUnwrap(store.puzzles.first?.id)
        try store.startTimer(id: id)
        XCTAssertNil(puzzle(id).timerRunningSince)
    }

    func testLeavingInProgressPauses() throws {
        let id = try addInProgress("Leave")
        try store.startTimer(id: id, now: Date().addingTimeInterval(-120))

        let current = puzzle(id)
        current.status = .todo
        try store.update(puzzle: current)

        XCTAssertNil(puzzle(id).timerRunningSince)
        XCTAssertGreaterThanOrEqual(puzzle(id).timerAccumulatedSeconds, 120)
    }

    func testCompleteWithEmptyLoggedTimeWritesTimerTime() throws {
        let id = try addInProgress("Prefill")
        try store.startTimer(id: id, now: Date().addingTimeInterval(-8_040))

        let current = puzzle(id)
        current.status = .completed
        try store.update(puzzle: current)

        let completed = puzzle(id)
        XCTAssertNil(completed.timerRunningSince)
        XCTAssertEqual(completed.estimatedTimeSpent?.hours, 2)
        XCTAssertEqual(completed.estimatedTimeSpent?.minutes, 14)
        let row = try XCTUnwrap(completed.completions.first)
        XCTAssertEqual(row.timeSpentHours, 2)
        XCTAssertEqual(row.timeSpentMinutes, 14)
    }

    func testCompleteKeepsExistingLoggedTime() throws {
        let id = try addInProgress("Logged")
        try store.startTimer(id: id, now: Date().addingTimeInterval(-600))

        let current = puzzle(id)
        current.estimatedTimeSpent = Puzzle.PuzzleTime(hours: 5)
        current.status = .completed
        try store.update(puzzle: current)

        let completed = puzzle(id)
        XCTAssertEqual(completed.estimatedTimeSpent?.hours, 5)
        XCTAssertNil(completed.estimatedTimeSpent?.minutes)
        XCTAssertEqual(completed.completions.first?.timeSpentHours, 5)
    }

    func testRedoZeroesTimer() throws {
        let id = try addInProgress("Redo")
        try store.startTimer(id: id, now: Date().addingTimeInterval(-600))
        let current = puzzle(id)
        current.status = .completed
        try store.update(puzzle: current)
        XCTAssertGreaterThan(puzzle(id).timerAccumulatedSeconds, 0)

        try store.startRedo(puzzle: puzzle(id))

        XCTAssertEqual(puzzle(id).status, .inProgress)
        XCTAssertEqual(puzzle(id).timerAccumulatedSeconds, 0)
        XCTAssertNil(puzzle(id).timerRunningSince)
    }

    func testUndoCompletionKeepsAccumulatedSeconds() throws {
        let id = try addInProgress("Undo")
        try store.startTimer(id: id, now: Date().addingTimeInterval(-600))
        let current = puzzle(id)
        current.status = .completed
        try store.update(puzzle: current)
        let accumulated = puzzle(id).timerAccumulatedSeconds

        try store.undoLastCompletion(puzzleID: id)

        XCTAssertEqual(puzzle(id).status, .inProgress)
        XCTAssertEqual(puzzle(id).timerAccumulatedSeconds, accumulated)
        XCTAssertNil(puzzle(id).timerRunningSince)
    }

    func testResetZeroesTimerAndKeepsLoggedTime() throws {
        let id = try addInProgress("Reset", time: Puzzle.PuzzleTime(hours: 1, minutes: 5))
        try store.startTimer(id: id, now: Date().addingTimeInterval(-600))
        try store.resetTimer(id: id)

        XCTAssertEqual(puzzle(id).timerAccumulatedSeconds, 0)
        XCTAssertNil(puzzle(id).timerRunningSince)
        XCTAssertEqual(puzzle(id).estimatedTimeSpent?.hours, 1)
        XCTAssertEqual(puzzle(id).estimatedTimeSpent?.minutes, 5)
    }

    func testEditSaveKeepsRunningTimer() throws {
        let id = try addInProgress("Edit")
        let start = Date().addingTimeInterval(-300)
        try store.startTimer(id: id, now: start)

        let draft = puzzle(id).copy()
        draft.notes = "Edited"
        try store.update(puzzle: draft)

        XCTAssertEqual(puzzle(id).timerRunningSince, start)
    }

    func testFutureAnchorIsPausedOnLoad() async throws {
        let id = try addInProgress("Skew")
        let record = try XCTUnwrap(
            try container.mainContext.fetch(FetchDescriptor<PuzzleRecord>()).first { $0.id == id }
        )
        record.timerAccumulatedSeconds = 45
        record.timerRunningSince = Date().addingTimeInterval(3_600)
        try container.mainContext.save()

        await store.fetchPuzzles()

        XCTAssertNil(puzzle(id).timerRunningSince)
        XCTAssertEqual(puzzle(id).timerAccumulatedSeconds, 45)
    }

    // MARK: - Helpers

    private func addInProgress(_ name: String, time: Puzzle.PuzzleTime? = nil) throws -> UUID {
        let puzzle = Puzzle.fixture(name: name, pieces: 500, estimatedTimeSpent: time)
        puzzle.status = .inProgress
        try store.add(puzzle: puzzle)
        return puzzle.id
    }

    private func puzzle(_ id: UUID) -> Puzzle {
        guard let match = store.puzzles.first(where: { $0.id == id }) else {
            XCTFail("Missing puzzle \(id)")
            return Puzzle.fixture()
        }
        return match
    }
}
