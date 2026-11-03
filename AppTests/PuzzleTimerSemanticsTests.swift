//
//  PuzzleTimerSemanticsTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class PuzzleTimerSemanticsTests: XCTestCase {
    private let anchor = Date(timeIntervalSince1970: 1_800_000_000)

    func testElapsedWhilePausedIsAccumulated() {
        XCTAssertEqual(PuzzleTimerSemantics.elapsedSeconds(accumulated: 125, runningSince: nil, now: anchor), 125)
        XCTAssertFalse(PuzzleTimerSemantics.isRunning(runningSince: nil, now: anchor))
    }

    func testElapsedWhileRunningAddsOpenSegment() {
        let now = anchor.addingTimeInterval(90)
        XCTAssertEqual(PuzzleTimerSemantics.elapsedSeconds(accumulated: 30, runningSince: anchor, now: now), 120)
        XCTAssertTrue(PuzzleTimerSemantics.isRunning(runningSince: anchor, now: now))
    }

    func testPauseResumeAccumulates() {
        let puzzle = Puzzle.fixture(name: "Timer", pieces: 500)
        puzzle.timerRunningSince = anchor
        PuzzleTimerSemantics.pause(puzzle, now: anchor.addingTimeInterval(600))
        XCTAssertEqual(puzzle.timerAccumulatedSeconds, 600)
        XCTAssertNil(puzzle.timerRunningSince)

        let resumed = anchor.addingTimeInterval(1_000)
        puzzle.timerRunningSince = resumed
        PuzzleTimerSemantics.pause(puzzle, now: resumed.addingTimeInterval(60))
        XCTAssertEqual(puzzle.timerAccumulatedSeconds, 660)
    }

    func testBackwardClockDropsOpenSegmentAndNeverGoesNegative() {
        let earlier = anchor.addingTimeInterval(-300)
        XCTAssertTrue(PuzzleTimerSemantics.isClockSkewed(runningSince: anchor, now: earlier))
        XCTAssertFalse(PuzzleTimerSemantics.isRunning(runningSince: anchor, now: earlier))
        XCTAssertEqual(PuzzleTimerSemantics.elapsedSeconds(accumulated: 45, runningSince: anchor, now: earlier), 45)
        XCTAssertEqual(PuzzleTimerSemantics.elapsedSeconds(accumulated: -10, runningSince: nil, now: earlier), 0)

        let puzzle = Puzzle.fixture(name: "Skew", pieces: 500)
        puzzle.timerAccumulatedSeconds = 45
        puzzle.timerRunningSince = anchor
        PuzzleTimerSemantics.pause(puzzle, now: earlier)
        XCTAssertEqual(puzzle.timerAccumulatedSeconds, 45)
        XCTAssertNil(puzzle.timerRunningSince)
    }

    func testRoundingToMinutes() {
        XCTAssertNil(PuzzleTimerSemantics.roundedMinutes(seconds: 0))
        XCTAssertEqual(PuzzleTimerSemantics.roundedMinutes(seconds: 1), 1)
        XCTAssertEqual(PuzzleTimerSemantics.roundedMinutes(seconds: 29), 1)
        XCTAssertEqual(PuzzleTimerSemantics.roundedMinutes(seconds: 89), 1)
        XCTAssertEqual(PuzzleTimerSemantics.roundedMinutes(seconds: 90), 2)
        XCTAssertEqual(PuzzleTimerSemantics.roundedMinutes(seconds: 8_040), 134)

        let time = PuzzleTimerSemantics.puzzleTime(seconds: 8_040)
        XCTAssertEqual(time?.hours, 2)
        XCTAssertEqual(time?.minutes, 14)
        XCTAssertEqual(time?.displayLabel, "2 hr 14 min")
        XCTAssertNil(PuzzleTimerSemantics.puzzleTime(seconds: 0))
    }

    func testCompletionPrefillOnlyWhenLoggedTimeEmpty() {
        XCTAssertEqual(PuzzleTimerSemantics.completionPrefill(timerSeconds: 3_600, logged: nil)?.hours, 1)
        XCTAssertEqual(
            PuzzleTimerSemantics.completionPrefill(timerSeconds: 3_600, logged: Puzzle.PuzzleTime())?.hours,
            1
        )
        XCTAssertNil(PuzzleTimerSemantics.completionPrefill(timerSeconds: 3_600, logged: Puzzle.PuzzleTime(hours: 3)))
        XCTAssertNil(PuzzleTimerSemantics.completionPrefill(timerSeconds: 3_600, logged: Puzzle.PuzzleTime(minutes: 5)))
        XCTAssertNil(PuzzleTimerSemantics.completionPrefill(timerSeconds: 0, logged: nil))
    }

    func testFormSuggestionHiddenWhenMatching() {
        XCTAssertNil(PuzzleTimerSemantics.formSuggestion(
            timerSeconds: 8_040,
            logged: Puzzle.PuzzleTime(hours: 2, minutes: 14)
        ))
        XCTAssertEqual(PuzzleTimerSemantics.formSuggestion(
            timerSeconds: 8_040,
            logged: Puzzle.PuzzleTime(hours: 2, minutes: 0)
        )?.minutes, 14)
        XCTAssertNil(PuzzleTimerSemantics.formSuggestion(timerSeconds: 0, logged: nil))
    }

    func testOtherRunningTimerMustPause() {
        let first = Puzzle.fixture(name: "A", pieces: 500)
        first.timerRunningSince = anchor
        let second = Puzzle.fixture(name: "B", pieces: 500)
        let idle = Puzzle.fixture(name: "C", pieces: 500)

        XCTAssertEqual(PuzzleTimerSemantics.idsToPause(startingID: second.id, in: [first, second, idle]), [first.id])
        XCTAssertEqual(PuzzleTimerSemantics.idsToPause(startingID: first.id, in: [first, second, idle]), [])
    }

    func testLabelsAndBuckets() {
        XCTAssertEqual(PuzzleTimerSemantics.clockLabel(seconds: 0), "0:00:00")
        XCTAssertEqual(PuzzleTimerSemantics.clockLabel(seconds: 8_045), "2:14:05")
        XCTAssertEqual(PuzzleTimerSemantics.clockLabel(seconds: 90_061), "25:01:01")
        XCTAssertEqual(PuzzleTimerSemantics.spokenLabel(seconds: 0), "0 seconds")
        XCTAssertFalse(PuzzleTimerSemantics.spokenLabel(seconds: 8_045).isEmpty)

        XCTAssertEqual(PuzzleTimerSemantics.durationBucket(seconds: 0), "under_15m")
        XCTAssertEqual(PuzzleTimerSemantics.durationBucket(seconds: 900), "15m_1h")
        XCTAssertEqual(PuzzleTimerSemantics.durationBucket(seconds: 3_600), "1h_3h")
        XCTAssertEqual(PuzzleTimerSemantics.durationBucket(seconds: 10_800), "over_3h")
    }

    func testCopyAndRecordRoundTripKeepTimerFields() {
        let puzzle = Puzzle.fixture(name: "Round trip", pieces: 1000)
        puzzle.status = .inProgress
        puzzle.timerAccumulatedSeconds = 321
        puzzle.timerRunningSince = anchor

        let copy = puzzle.copy()
        XCTAssertEqual(copy.timerAccumulatedSeconds, 321)
        XCTAssertEqual(copy.timerRunningSince, anchor)

        let record = PuzzleRecord(from: puzzle)
        XCTAssertEqual(record.timerAccumulatedSeconds, 321)
        XCTAssertEqual(record.timerRunningSince, anchor)
        let restored = record.toPuzzle()
        XCTAssertEqual(restored.timerAccumulatedSeconds, 321)
        XCTAssertEqual(restored.timerRunningSince, anchor)

        copy.timerAccumulatedSeconds = 10
        copy.timerRunningSince = nil
        record.apply(from: copy)
        XCTAssertEqual(record.timerAccumulatedSeconds, 10)
        XCTAssertNil(record.timerRunningSince)
    }
}
