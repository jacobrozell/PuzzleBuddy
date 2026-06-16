//
//  PuzzleSerializationTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class PuzzleSerializationTests: XCTestCase {
    func testPuzzleTimeRoundTrip() {
        let time = Puzzle.PuzzleTime(hours: 2, minutes: 30)
        XCTAssertEqual(time.toName(), "2hr:30min")
        XCTAssertEqual(time.toMin(), 150)

        let parsed = Puzzle.PuzzleTime(name: "2hr:30min")
        XCTAssertEqual(parsed.hours, 2)
        XCTAssertEqual(parsed.minutes, 30)
    }

    func testGetDataFieldsContainsCoreKeys() {
        let puzzle = Puzzle.fixture(name: "Sunset", pieces: 500)
        puzzle.rating = .four
        puzzle.difficulty = .three
        puzzle.status = .completed

        let fields = puzzle.getDataFields()
        XCTAssertEqual(fields["name"] as? String, "Sunset")
        XCTAssertEqual(fields["pieces"] as? Int, 500)
        XCTAssertEqual(fields["rating"] as? Double, 4.0)
        XCTAssertEqual(fields["difficulty"] as? String, "3")
        XCTAssertEqual(fields["status"] as? String, "Completed")
        XCTAssertNotNil(fields["id"])
    }

    func testRatingCaseIterable() {
        XCTAssertEqual(Puzzle.Rating.allCases.count, 10)
        XCTAssertEqual(Puzzle.Rating.five.rawValue, 5.0)
    }

    func testStatusLabels() {
        XCTAssertEqual(Puzzle.Status.todo.rawValue, "To-Do")
        XCTAssertEqual(Puzzle.Status.completed.rawValue, "Completed")
    }

    func testFromDataRoundTrip() {
        let original = Puzzle.fixture(name: "Galaxy", pieces: 750, rating: .fourHalf, difficulty: .three)
        original.status = .completed
        original.estimatedTimeSpent = Puzzle.PuzzleTime(hours: 3, minutes: 15)

        let fields = original.getDataFields()
        let restored = Puzzle.fromData(fields)

        XCTAssertEqual(restored.name, "Galaxy")
        XCTAssertEqual(restored.pieces, 750)
        XCTAssertEqual(restored.rating, .fourHalf)
        XCTAssertEqual(restored.difficulty, .three)
        XCTAssertEqual(restored.status, .completed)
        XCTAssertEqual(restored.estimatedTimeSpent?.toName(), "3hr:15min")
    }
}
