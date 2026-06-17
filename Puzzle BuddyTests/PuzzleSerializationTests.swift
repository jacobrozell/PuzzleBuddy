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
        XCTAssertEqual(Puzzle.Status.inProgress.rawValue, "In-Progress")
        XCTAssertEqual(Puzzle.Status.completed.rawValue, "Completed")
        XCTAssertEqual(Puzzle.Status.allCases.count, 3)
    }

    func testFromDataInProgressStatus() {
        let puzzle = Puzzle.fixture(name: "Active", pieces: 500)
        puzzle.status = .inProgress

        let restored = Puzzle.fromData(puzzle.getDataFields())
        XCTAssertEqual(restored.status, .inProgress)
        XCTAssertEqual(restored.getDataFields()["status"] as? String, "In-Progress")
    }

    func testFromDataRoundTripTags() {
        let original = Puzzle.fixture(name: "Tagged", pieces: 500)
        original.tags = ["Cozy", "Winter"]

        let fields = original.getDataFields()
        let restored = Puzzle.fromData(fields)

        XCTAssertEqual(restored.tags, ["Cozy", "Winter"])
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

    func testPuzzleTimeMissingValuesUseDefaults() {
        let empty = Puzzle.PuzzleTime()
        XCTAssertEqual(empty.toName(), "N/A")
        XCTAssertEqual(empty.toMin(), 1)

        let zeroed = Puzzle.PuzzleTime(hours: 0, minutes: 0)
        XCTAssertEqual(zeroed.toMin(), 1)
    }

    func testDifficultyRoundTripInDataFields() {
        let puzzle = Puzzle.fixture(name: "Hard", pieces: 1000, difficulty: .five)
        let fields = puzzle.getDataFields()
        let restored = Puzzle.fromData(fields)
        XCTAssertEqual(restored.difficulty, .five)
    }

    func testFromDataPreservesUUID() {
        let id = UUID()
        let puzzle = Puzzle.fixture(name: "ID Test", pieces: 100)
        puzzle.id = id

        let restored = Puzzle.fromData(puzzle.getDataFields())
        XCTAssertEqual(restored.id, id)
    }

    func testFromDataFallsBackWhenFieldsMissing() {
        let restored = Puzzle.fromData([:])
        XCTAssertEqual(restored.name, "")
        XCTAssertNil(restored.pieces)
        XCTAssertEqual(restored.rating, .none)
        XCTAssertEqual(restored.difficulty, .none)
        XCTAssertEqual(restored.status, .todo)
    }

    func testGetDataFieldsIncludesMissingPiecesAndNotes() {
        let puzzle = Puzzle.fixture(name: "Thrift", pieces: 500)
        puzzle.hasMissingPieces = true
        puzzle.notes = "Missing 3 edge pieces"
        puzzle.source = "Amazon"
        puzzle.progressPercent = 55
        puzzle.barcode = "012345678905"

        let fields = puzzle.getDataFields()
        XCTAssertEqual(fields["hasMissingPieces"] as? Bool, true)
        XCTAssertEqual(fields["notes"] as? String, "Missing 3 edge pieces")
        XCTAssertEqual(fields["source"] as? String, "Amazon")
        XCTAssertEqual(fields["progressPercent"] as? Int, 55)
        XCTAssertEqual(fields["barcode"] as? String, "012345678905")
    }

    func testFromDataRestoresMissingPiecesAndNotes() {
        var fields = Puzzle.fixture(name: "Thrift", pieces: 500).getDataFields()
        fields["hasMissingPieces"] = true
        fields["notes"] = "Box damaged"
        fields["source"] = "Gift from Dad"
        fields["progressPercent"] = 20
        fields["barcode"] = "012345678905"

        let restored = Puzzle.fromData(fields)
        XCTAssertTrue(restored.hasMissingPieces)
        XCTAssertEqual(restored.notes, "Box damaged")
        XCTAssertEqual(restored.source, "Gift from Dad")
        XCTAssertEqual(restored.progressPercent, 20)
        XCTAssertEqual(restored.barcode, "012345678905")
    }
}
