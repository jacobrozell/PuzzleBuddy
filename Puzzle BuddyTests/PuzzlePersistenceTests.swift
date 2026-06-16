//
//  PuzzlePersistenceTests.swift
//  Puzzle BuddyTests
//

import SwiftData
import XCTest
@testable import Puzzle_Buddy

@MainActor
final class PuzzlePersistenceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: PuzzleRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
    }

    func testPuzzleRecordRoundTrip() throws {
        let puzzle = Puzzle.fixture(name: "Galaxy", pieces: 750, rating: .fourHalf, difficulty: .three)
        puzzle.status = .completed
        puzzle.estimatedTimeSpent = Puzzle.PuzzleTime(hours: 3, minutes: 15)

        let record = PuzzleRecord(from: puzzle)
        context.insert(record)
        try context.save()

        let restored = record.toPuzzle()
        XCTAssertEqual(restored.id, puzzle.id)
        XCTAssertEqual(restored.name, "Galaxy")
        XCTAssertEqual(restored.pieces, 750)
        XCTAssertEqual(restored.rating, .fourHalf)
        XCTAssertEqual(restored.difficulty, .three)
        XCTAssertEqual(restored.status, .completed)
        XCTAssertEqual(restored.estimatedTimeSpent?.toName(), "3hr:15min")
    }

    func testPuzzleStorePersistsLocally() async throws {
        let store = PuzzleStore(modelContext: context)
        let puzzle = Puzzle.fixture(name: "Sunset", pieces: 500)
        try store.add(puzzle: puzzle)

        let reloaded = PuzzleStore(modelContext: context)
        await reloaded.fetchPuzzles()

        XCTAssertEqual(reloaded.puzzles.count, 1)
        XCTAssertEqual(reloaded.puzzles.first?.name, "Sunset")
    }
}
