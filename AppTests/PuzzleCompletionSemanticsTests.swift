//
//  PuzzleCompletionSemanticsTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class PuzzleCompletionSemanticsTests: XCTestCase {
    func testMakeCompletionCapturesPuzzleSnapshot() {
        var puzzle = Puzzle.fixture(name: "Done", pieces: 500, rating: .four)
        puzzle.status = .completed
        puzzle.startDate = Date(timeIntervalSince1970: 1_000)
        puzzle.completionDate = Date(timeIntervalSince1970: 10_000)
        puzzle.estimatedTimeSpent = Puzzle.PuzzleTime(hours: 2, minutes: 30)

        let completion = PuzzleCompletionSemantics.makeCompletion(from: puzzle, number: 1)

        XCTAssertEqual(completion.completionNumber, 1)
        XCTAssertEqual(completion.startedAt, puzzle.startDate)
        XCTAssertEqual(completion.completedAt, puzzle.completionDate)
        XCTAssertEqual(completion.timeSpentHours, 2)
        XCTAssertEqual(completion.timeSpentMinutes, 30)
        XCTAssertEqual(completion.rating, 4.0)
    }

    func testSortedNewestFirstOrdersByCompletionNumber() {
        let older = PuzzleCompletion(completionNumber: 1, completedAt: Date())
        let newer = PuzzleCompletion(completionNumber: 2, completedAt: Date())
        let sorted = PuzzleCompletionSemantics.sortedNewestFirst([older, newer])
        XCTAssertEqual(sorted.map(\.completionNumber), [2, 1])
    }

    func testTimeSpentLabelFormatsHoursAndMinutes() {
        let completion = PuzzleCompletion(
            completionNumber: 1,
            completedAt: Date(),
            timeSpentHours: 1,
            timeSpentMinutes: 5
        )
        XCTAssertEqual(completion.timeSpentLabel, "1 hr 5 min")
    }
}
