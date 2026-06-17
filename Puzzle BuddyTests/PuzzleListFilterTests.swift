//
//  PuzzleListFilterTests.swift
//  Puzzle BuddyTests
//

import XCTest
import UIKit
@testable import Puzzle_Buddy

final class PuzzleListFilterTests: XCTestCase {
    func testAllFilterReturnsEveryPuzzle() {
        let puzzles = samplePuzzles()
        let filtered = PuzzleListStatusFilter.filter(puzzles, by: .all)
        XCTAssertEqual(filtered.map(\.name), ["Shelf", "Done"])
    }

    func testTodoFilterReturnsOnlyTodo() {
        let puzzles = samplePuzzles()
        let filtered = PuzzleListStatusFilter.filter(puzzles, by: .todo)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Shelf")
        XCTAssertEqual(filtered.first?.status, .todo)
    }

    func testCompletedFilterReturnsOnlyCompleted() {
        let puzzles = samplePuzzles()
        let filtered = PuzzleListStatusFilter.filter(puzzles, by: .completed)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "Done")
        XCTAssertEqual(filtered.first?.status, .completed)
    }

    func testInProgressFilterReturnsOnlyInProgress() {
        let puzzles = samplePuzzles() + [inProgressPuzzle()]
        let filtered = PuzzleListStatusFilter.filter(puzzles, by: .inProgress)
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.name, "On Table")
        XCTAssertEqual(filtered.first?.status, .inProgress)
    }

    func testInProgressEmptyStateMessage() {
        XCTAssertTrue(PuzzleListStatusFilter.inProgress.emptyStateMessage(hasSearchQuery: false).contains("table"))
    }

    func testEmptyStateMessages() {
        XCTAssertTrue(PuzzleListStatusFilter.todo.emptyStateMessage(hasSearchQuery: false).contains("shelf"))
        XCTAssertTrue(PuzzleListStatusFilter.completed.emptyStateMessage(hasSearchQuery: false).contains("completed"))
        XCTAssertTrue(PuzzleListStatusFilter.all.emptyStateMessage(hasSearchQuery: false).contains("Add puzzle"))
        XCTAssertTrue(PuzzleListStatusFilter.all.emptyStateMessage(hasSearchQuery: true).contains("search"))
    }

    func testSearchMatchesNameCaseInsensitively() {
        let puzzles = samplePuzzles() + [Puzzle.fixture(name: "Alpine Meadow", pieces: 300)]
        let results = PuzzleListQuery.search(puzzles, query: "alpine")
        XCTAssertEqual(results.map(\.name), ["Alpine Meadow"])
    }

    func testSearchMatchesBrandSource() {
        let puzzle = Puzzle.fixture(name: "Untitled", pieces: 500)
        puzzle.source = "Ravensburger"
        let results = PuzzleListQuery.search([puzzle], query: "ravens")
        XCTAssertEqual(results.count, 1)
    }

    func testSearchMatchesBarcodeDigits() {
        let puzzle = Puzzle.fixture(name: "Barcode Puzzle", pieces: 1000)
        puzzle.barcode = "4005556197523"
        let results = PuzzleListQuery.search([puzzle], query: "6197523")
        XCTAssertEqual(results.count, 1)
    }

    func testFilterNeedsPhotoOnly() {
        let withPhoto = Puzzle.fixture(name: "Photo", pieces: 500)
        withPhoto.image = UIImage(systemName: "puzzlepiece")
        let withoutPhoto = Puzzle.fixture(name: "No Photo", pieces: 500)

        let results = PuzzleListQuery.filterNeedsPhoto([withPhoto, withoutPhoto], needsPhotoOnly: true)
        XCTAssertEqual(results.map(\.name), ["No Photo"])
    }

    func testFilterPieceCountRanges() {
        let small = Puzzle.fixture(name: "Small", pieces: 300)
        let medium = Puzzle.fixture(name: "Medium", pieces: 1000)
        let large = Puzzle.fixture(name: "Large", pieces: 2000)

        let thousands = PuzzleListQuery.filterPieceCount(
            [small, medium, large],
            pieceCountFilter: .thousand
        )
        XCTAssertEqual(thousands.map(\.name), ["Medium"])

        let big = PuzzleListQuery.filterPieceCount(
            [small, medium, large],
            pieceCountFilter: .atLeast1500
        )
        XCTAssertEqual(big.map(\.name), ["Large"])
    }

    func testDefaultSortUsesNameForTodoTab() {
        XCTAssertEqual(PuzzleListSortOption.defaultFor(statusFilter: .todo), .name)
        XCTAssertEqual(PuzzleListSortOption.defaultFor(statusFilter: .completed), .completionDate)
    }

    func testSearchWithEmptyQueryReturnsAll() {
        let puzzles = samplePuzzles()
        XCTAssertEqual(PuzzleListQuery.search(puzzles, query: "").map(\.name), puzzles.map(\.name))
        XCTAssertEqual(PuzzleListQuery.search(puzzles, query: "   ").map(\.name), puzzles.map(\.name))
    }

    func testSortByCompletionDateNewestFirst() {
        let older = Puzzle.fixture(name: "Older", pieces: 100)
        older.completionDate = Date(timeIntervalSince1970: 1_000)
        let newer = Puzzle.fixture(name: "Newer", pieces: 200)
        newer.completionDate = Date(timeIntervalSince1970: 2_000)

        let sorted = PuzzleListQuery.sort([older, newer], by: .completionDate)
        XCTAssertEqual(sorted.map(\.name), ["Newer", "Older"])
    }

    func testSortByRatingHighestFirst() {
        let low = Puzzle.fixture(name: "Low", pieces: 100, rating: .two)
        let high = Puzzle.fixture(name: "High", pieces: 100, rating: .five)
        let sorted = PuzzleListQuery.sort([low, high], by: .rating)
        XCTAssertEqual(sorted.map(\.name), ["High", "Low"])
    }

    func testSortByPiecesLargestFirst() {
        let small = Puzzle.fixture(name: "Small", pieces: 300)
        let large = Puzzle.fixture(name: "Large", pieces: 2000)
        let sorted = PuzzleListQuery.sort([small, large], by: .pieces)
        XCTAssertEqual(sorted.map(\.name), ["Large", "Small"])
    }

    func testSortByNameAscending() {
        let zebra = Puzzle.fixture(name: "Zebra", pieces: 100)
        let alpha = Puzzle.fixture(name: "Alpha", pieces: 100)
        let sorted = PuzzleListQuery.sort([zebra, alpha], by: .name)
        XCTAssertEqual(sorted.map(\.name), ["Alpha", "Zebra"])
    }

    func testFilterMissingPiecesOnly() {
        let flagged = Puzzle.fixture(name: "Thrift", pieces: 500)
        flagged.hasMissingPieces = true
        let clean = Puzzle.fixture(name: "New", pieces: 1000)

        let results = PuzzleListQuery.filterMissingPieces([flagged, clean], missingPiecesOnly: true)
        XCTAssertEqual(results.map(\.name), ["Thrift"])
    }

    func testResultCountLabel() {
        XCTAssertEqual(
            PuzzleListQuery.resultCountLabel(displayedCount: 12, totalCount: 1000, hasActiveFilters: true),
            "Showing 12 of 1,000"
        )
        XCTAssertEqual(
            PuzzleListQuery.resultCountLabel(displayedCount: 1000, totalCount: 1000, hasActiveFilters: false),
            "1,000 puzzles"
        )
    }

    func testSearchMatchesTag() {
        let puzzle = Puzzle.fixture(name: "Untitled", pieces: 500)
        puzzle.tags = ["Wysocki", "cozy"]
        let results = PuzzleListQuery.search([puzzle], query: "wysock")
        XCTAssertEqual(results.count, 1)
    }

    func testFilterByTag() {
        let tagged = Puzzle.fixture(name: "Tagged", pieces: 500)
        tagged.tags = ["Winter"]
        let plain = Puzzle.fixture(name: "Plain", pieces: 500)

        let results = PuzzleListQuery.apply(
            puzzles: [tagged, plain],
            statusFilter: .all,
            searchText: "",
            sortOption: .name,
            tagFilter: "winter"
        )
        XCTAssertEqual(results.map(\.name), ["Tagged"])
    }

    func testHasActiveFiltersIncludesTagFilter() {
        XCTAssertTrue(
            PuzzleListQuery.hasActiveFilters(
                statusFilter: .all,
                searchText: "",
                missingPiecesOnly: false,
                tagFilter: "Cozy"
            )
        )
    }

    func testApplyCombinesStatusSearchAndSort() {
        let shelf = Puzzle.fixture(name: "Winter Cabin", pieces: 500, rating: .three)
        let done = Puzzle.fixture(name: "Winter Lights", pieces: 1000, rating: .five)
        done.status = .completed

        let results = PuzzleListQuery.apply(
            puzzles: [shelf, done],
            statusFilter: .all,
            searchText: "winter",
            sortOption: .rating
        )

        XCTAssertEqual(results.map(\.name), ["Winter Lights", "Winter Cabin"])
    }

    private func samplePuzzles() -> [Puzzle] {
        let todo = Puzzle.fixture(name: "Shelf", pieces: 500)
        let completed = Puzzle.fixture(name: "Done", pieces: 1000)
        completed.status = .completed
        return [todo, completed]
    }

    private func inProgressPuzzle() -> Puzzle {
        let puzzle = Puzzle.fixture(name: "On Table", pieces: 300)
        puzzle.status = .inProgress
        return puzzle
    }
}
