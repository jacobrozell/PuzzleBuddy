//
//  PuzzleDateSemanticsTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class PuzzleDateSemanticsTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testProgressDaysForInProgressPuzzle() {
        let start = date("2026-06-01")
        let now = date("2026-06-04")
        var puzzle = Puzzle.fixture(name: "Active", pieces: 500, estimatedTimeSpent: nil)
        puzzle.status = .inProgress
        puzzle.startDate = start
        puzzle.completionDate = start

        XCTAssertEqual(
            PuzzleDateSemantics.progressDaysLabel(for: puzzle, calendar: calendar, now: now),
            "3 days puzzling"
        )
    }

    func testProgressDaysForCompletedPuzzle() {
        let start = date("2026-06-01")
        let finish = date("2026-06-03")
        var puzzle = Puzzle.fixture(name: "Done", pieces: 500, estimatedTimeSpent: nil)
        puzzle.status = .completed
        puzzle.startDate = start
        puzzle.completionDate = finish

        XCTAssertEqual(
            PuzzleDateSemantics.progressDaysLabel(for: puzzle, calendar: calendar),
            "Finished in 2 days"
        )
    }

    func testNoteStatusChangedSetsStartDateWhenEnteringInProgress() {
        var puzzle = Puzzle.fixture(name: "Shelf", pieces: 500, estimatedTimeSpent: nil)
        puzzle.noteStatusChanged(from: .todo, to: .inProgress)
        XCTAssertNotNil(puzzle.startDate)
        XCTAssertEqual(puzzle.progressPercent, 10)
    }

    private func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)!
    }
}
