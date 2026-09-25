//
//  PuzzleLoanAndFriendTests.swift
//  Puzzle BuddyTests
//

import SwiftData
import XCTest
@testable import PuzzleBuddy

@MainActor
final class PuzzleLoanAndFriendTests: XCTestCase {
    private var container: ModelContainer!
    private var store: PuzzleStore!

    override func setUp() {
        super.setUp()
        container = PuzzleModelContainer.makeInMemory()
        store = PuzzleStore(modelContext: container.mainContext)
    }

    override func tearDown() {
        store = nil
        container = nil
        super.tearDown()
    }

    func testFindOrCreateIsCaseInsensitive() throws {
        let first = try store.friends.findOrCreate(displayName: "Mom")
        let second = try store.friends.findOrCreate(displayName: "mom")
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(store.friends.friends.count, 1)
    }

    func testMarkOnLoanCreatesFriendAndPersists() throws {
        let puzzle = Puzzle.fixture(name: "Loaned Puzzle", pieces: 500)
        puzzle.status = .completed
        puzzle.isOnLoan = true
        puzzle.loanedToDisplayName = "Mom"
        try store.add(puzzle: puzzle)

        let saved = try XCTUnwrap(store.puzzles.first)
        XCTAssertTrue(saved.isOnLoan)
        XCTAssertNotNil(saved.loanedToFriendID)
        XCTAssertEqual(saved.loanedToDisplayName, "Mom")
        XCTAssertNotNil(saved.loanedAt)
        XCTAssertEqual(store.friends.friends.count, 1)
    }

    func testMarkReturnedClearsLoanKeepsFriend() throws {
        let puzzle = Puzzle.fixture(name: "Return Me", pieces: 300)
        puzzle.isOnLoan = true
        puzzle.loanedToDisplayName = "Dad"
        try store.add(puzzle: puzzle)

        let saved = try XCTUnwrap(store.puzzles.first)
        try store.markReturned(puzzle: saved)

        let refreshed = try XCTUnwrap(store.puzzles.first)
        XCTAssertFalse(refreshed.isOnLoan)
        XCTAssertNil(refreshed.loanedToFriendID)
        XCTAssertNil(refreshed.loanedAt)
        XCTAssertEqual(store.friends.friends.count, 1)
    }

    func testGiftedDispositionClearsLoan() throws {
        let puzzle = Puzzle.fixture(name: "Gifted Away", pieces: 1000)
        puzzle.status = .completed
        puzzle.isOnLoan = true
        puzzle.loanedToDisplayName = "Sam"
        try store.add(puzzle: puzzle)

        let saved = try XCTUnwrap(store.puzzles.first)
        saved.disposition = .gifted
        try store.update(puzzle: saved)

        let refreshed = try XCTUnwrap(store.puzzles.first)
        XCTAssertFalse(refreshed.isOnLoan)
        XCTAssertNil(refreshed.loanedToFriendID)
    }

    func testDeleteFriendBlockedWhenOnLoan() throws {
        let puzzle = Puzzle.fixture(name: "Still Out", pieces: 750)
        puzzle.isOnLoan = true
        puzzle.loanedToDisplayName = "Alex"
        try store.add(puzzle: puzzle)

        let friend = try XCTUnwrap(store.friends.friends.first)
        XCTAssertThrowsError(
            try store.friends.delete(friend, loanReferenceCount: store.loanReferenceCount(for: friend.id))
        ) { error in
            XCTAssertEqual(error as? FriendStoreError, .referencedByLoans(count: 1))
        }
    }

    func testOverdueSemanticsAndFilter() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01

        let overdue = Puzzle.fixture(name: "Late", pieces: 100)
        overdue.isOnLoan = true
        overdue.dueBackDate = calendar.date(byAdding: .day, value: -1, to: now)

        let dueToday = Puzzle.fixture(name: "Today", pieces: 100)
        dueToday.isOnLoan = true
        dueToday.dueBackDate = now

        let home = Puzzle.fixture(name: "Home", pieces: 100)

        XCTAssertTrue(PuzzleLoanSemantics.isOverdue(overdue, now: now, calendar: calendar))
        XCTAssertFalse(PuzzleLoanSemantics.isOverdue(dueToday, now: now, calendar: calendar))
        XCTAssertFalse(PuzzleLoanSemantics.isOverdue(home, now: now, calendar: calendar))
        XCTAssertEqual(PuzzleLoanSemantics.listBadgeTitle(for: overdue, now: now, calendar: calendar), "Overdue")
        XCTAssertEqual(PuzzleLoanSemantics.listBadgeTitle(for: dueToday, now: now, calendar: calendar), "On loan")
        XCTAssertTrue(PuzzleLoanSemantics.dueBackDisplayValue(for: overdue, now: now, calendar: calendar)?.contains("Overdue") == true)

        let filtered = PuzzleListQuery.filterOverdueOnly(
            [overdue, dueToday, home],
            overdueOnly: true,
            now: now,
            calendar: calendar
        )
        XCTAssertEqual(filtered.map(\.name), ["Late"])
    }

    func testFilterOnLoanOnly() {
        let home = Puzzle.fixture(name: "Home", pieces: 100)
        let out = Puzzle.fixture(name: "Out", pieces: 200)
        out.isOnLoan = true
        out.loanedToDisplayName = "Mom"

        let filtered = PuzzleListQuery.filterOnLoanOnly([home, out], onLoanOnly: true)
        XCTAssertEqual(filtered.map(\.name), ["Out"])
    }

    func testSearchMatchesLoanedToName() {
        let puzzle = Puzzle.fixture(name: "Skyline", pieces: 1000)
        puzzle.isOnLoan = true
        puzzle.loanedToDisplayName = "Mom"

        let results = PuzzleListQuery.search([puzzle], query: "mom")
        XCTAssertEqual(results.count, 1)
    }

    func testPickNextExcludesOnLoan() {
        let available = Puzzle.fixture(name: "Shelf", pieces: 500)
        available.status = .todo
        let lent = Puzzle.fixture(name: "Lent", pieces: 500)
        lent.status = .todo
        lent.isOnLoan = true

        let eligible = PuzzleRandomPicker.eligible(
            from: [available, lent],
            includeInProgress: false,
            pieceCountFilter: .any,
            tagFilter: nil
        )
        XCTAssertEqual(eligible.map(\.name), ["Shelf"])
    }

    func testCollectionStatsOnLoanCount() {
        let a = Puzzle.fixture(name: "A", pieces: 100)
        a.isOnLoan = true
        let b = Puzzle.fixture(name: "B", pieces: 100)
        let stats = CollectionStats.compute(from: [a, b])
        XCTAssertEqual(stats.onLoanCount, 1)
    }

    func testJSONRoundTripPreservesLoanAndFriends() throws {
        let puzzle = Puzzle.fixture(name: "Export Loan", pieces: 500)
        puzzle.isOnLoan = true
        puzzle.loanedToDisplayName = "Mom"
        puzzle.dueBackDate = Date(timeIntervalSince1970: 1_700_000_000)
        try store.add(puzzle: puzzle)

        let data = try PuzzleCollectionExporter.jsonData(
            from: store.puzzles,
            friends: store.friends.friends
        )
        let parsed = try PuzzleCollectionJSONImporter.parse(from: data)
        XCTAssertEqual(parsed.friends.count, 1)
        XCTAssertEqual(parsed.friends.first?.displayName, "Mom")
        XCTAssertTrue(parsed.puzzles.first?.isOnLoan == true)
        XCTAssertEqual(parsed.puzzles.first?.loanedToFriendID, store.puzzles.first?.loanedToFriendID)
    }

    func testClearAllPuzzlesKeepsFriends() throws {
        let puzzle = Puzzle.fixture(name: "Temp", pieces: 100)
        puzzle.isOnLoan = true
        puzzle.loanedToDisplayName = "Mom"
        try store.add(puzzle: puzzle)
        XCTAssertEqual(store.friends.friends.count, 1)

        try store.clearAllPuzzles()
        store.friends.reload()
        XCTAssertTrue(store.puzzles.isEmpty)
        XCTAssertEqual(store.friends.friends.count, 1)
    }
}
