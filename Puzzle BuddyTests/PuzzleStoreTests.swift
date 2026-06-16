//
//  PuzzleStoreTests.swift
//  Puzzle BuddyTests
//

import SwiftData
import XCTest
@testable import Puzzle_Buddy

@MainActor
final class PuzzleStoreTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: PuzzleRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
    }

    func testFetchPuzzlesLoadsLocalRecords() async throws {
        let seed = PuzzleStore(modelContext: context)
        try seed.add(puzzle: Puzzle.fixture(name: "Local", pieces: 300))

        let store = PuzzleStore(modelContext: context)
        await store.fetchPuzzles()

        XCTAssertEqual(store.puzzles.count, 1)
        XCTAssertEqual(store.puzzles.first?.name, "Local")
        XCTAssertEqual(store.state, .done)
    }

    func testUpdatePersistsChangesLocally() async throws {
        let store = PuzzleStore(modelContext: context)
        var puzzle = Puzzle.fixture(name: "Before", pieces: 100)
        try store.add(puzzle: puzzle)

        puzzle.name = "After"
        puzzle.pieces = 250
        puzzle.status = .completed
        store.update(puzzle: puzzle)

        let reloaded = PuzzleStore(modelContext: context)
        await reloaded.fetchPuzzles()

        XCTAssertEqual(reloaded.puzzles.count, 1)
        XCTAssertEqual(reloaded.puzzles.first?.name, "After")
        XCTAssertEqual(reloaded.puzzles.first?.pieces, 250)
        XCTAssertEqual(reloaded.puzzles.first?.status, .completed)
    }

    func testDeleteRemovesPuzzleLocally() async throws {
        let store = PuzzleStore(modelContext: context)
        try store.add(puzzle: Puzzle.fixture(name: "Keep", pieces: 100))
        try store.add(puzzle: Puzzle.fixture(name: "Remove", pieces: 200))

        store.delete(at: IndexSet(integer: 1))

        XCTAssertEqual(store.puzzles.count, 1)
        XCTAssertEqual(store.puzzles.first?.name, "Keep")

        let reloaded = PuzzleStore(modelContext: context)
        await reloaded.fetchPuzzles()
        XCTAssertEqual(reloaded.puzzles.count, 1)
    }

    func testFetchPuzzlesSortsByCompletionDateDescending() async throws {
        let older = Puzzle.fixture(name: "Older", pieces: 100)
        older.completionDate = Date(timeIntervalSince1970: 1_000)

        let newer = Puzzle.fixture(name: "Newer", pieces: 200)
        newer.completionDate = Date(timeIntervalSince1970: 2_000)

        let store = PuzzleStore(modelContext: context)
        try store.add(puzzle: older)
        try store.add(puzzle: newer)

        await store.fetchPuzzles()

        XCTAssertEqual(store.puzzles.map(\.name), ["Newer", "Older"])
    }
}
