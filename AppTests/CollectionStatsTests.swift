//
//  CollectionStatsTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class CollectionStatsTests: XCTestCase {
    private var calendar: Calendar!
    private var referenceDate: Date!

    override func setUpWithError() throws {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = cal
        referenceDate = cal.date(from: DateComponents(year: 2026, month: 6, day: 15))!
    }

    func testComputeEmptyCollection() {
        let stats = CollectionStats.compute(from: [], calendar: calendar, now: referenceDate)

        XCTAssertEqual(stats.completedCount, 0)
        XCTAssertEqual(stats.totalCount, 0)
        XCTAssertEqual(stats.inProgressCount, 0)
        XCTAssertEqual(stats.totalPiecesCompleted, 0)
        XCTAssertEqual(stats.totalMinutesPuzzling, 0)
        XCTAssertEqual(stats.backlogCount, 0)
        XCTAssertEqual(stats.wishlistCount, 0)
        XCTAssertEqual(stats.abandonedCount, 0)
        XCTAssertEqual(stats.missingPiecesCount, 0)
        XCTAssertNil(stats.averageRating)
        XCTAssertNil(stats.averageDaysToComplete)
        XCTAssertNil(stats.favoritePieceCount)
        XCTAssertEqual(stats.completionsThisMonth, 0)
        XCTAssertEqual(stats.completionsThisYear, 0)
        XCTAssertNil(stats.biggestCompletedPieces)
        XCTAssertNil(stats.smallestCompletedPieces)
        XCTAssertTrue(stats.topTags.isEmpty)
    }

    func testComputeAggregatesCompletedAndBacklog() {
        let completed = makePuzzle(name: "Done", pieces: 500, status: .completed, rating: .four)
        completed.estimatedTimeSpent = Puzzle.PuzzleTime(hours: 2, minutes: 30)
        completed.completionDate = referenceDate

        let todo = makePuzzle(name: "Shelf", pieces: 1000, status: .todo)

        let stats = CollectionStats.compute(
            from: [completed, todo],
            calendar: calendar,
            now: referenceDate
        )

        XCTAssertEqual(stats.completedCount, 1)
        XCTAssertEqual(stats.totalCount, 2)
        XCTAssertEqual(stats.inProgressCount, 0)
        XCTAssertEqual(stats.totalPiecesCompleted, 500)
        XCTAssertEqual(stats.totalMinutesPuzzling, 150)
        XCTAssertEqual(stats.backlogCount, 1)
        XCTAssertEqual(stats.missingPiecesCount, 0)
        XCTAssertEqual(stats.averageRating, 4.0)
        XCTAssertEqual(stats.favoritePieceCount, 500)
        XCTAssertEqual(stats.completionsThisMonth, 1)
        XCTAssertEqual(stats.completionsThisYear, 1)
        XCTAssertEqual(stats.biggestCompletedPieces, 500)
        XCTAssertEqual(stats.smallestCompletedPieces, 500)
    }

    func testComputeIgnoresPuzzlesWithoutTimeOrRating() {
        let completed = makePuzzle(name: "No time", pieces: 300, status: .completed, rating: .none)
        completed.estimatedTimeSpent = nil
        completed.completionDate = referenceDate

        let stats = CollectionStats.compute(from: [completed], calendar: calendar, now: referenceDate)

        XCTAssertEqual(stats.totalMinutesPuzzling, 0)
        XCTAssertNil(stats.averageRating)
    }

    func testMinutesSpentHoursOnly() {
        let completed = makePuzzle(name: "Hours only", pieces: 500, status: .completed)
        completed.estimatedTimeSpent = Puzzle.PuzzleTime(hours: 2, minutes: nil)
        completed.completionDate = referenceDate

        let stats = CollectionStats.compute(from: [completed], calendar: calendar, now: referenceDate)
        XCTAssertEqual(stats.totalMinutesPuzzling, 120)
    }

    func testMinutesSpentMinutesOnly() {
        let completed = makePuzzle(name: "Minutes only", pieces: 500, status: .completed)
        completed.estimatedTimeSpent = Puzzle.PuzzleTime(hours: nil, minutes: 45)
        completed.completionDate = referenceDate

        let stats = CollectionStats.compute(from: [completed], calendar: calendar, now: referenceDate)
        XCTAssertEqual(stats.totalMinutesPuzzling, 45)
    }

    func testFavoritePieceCountUsesMode() {
        XCTAssertEqual(CollectionStats.favoritePieceCount(from: [500, 1000, 500, 300]), 500)
    }

    func testFavoritePieceCountFallsBackToMedianWhenAllUnique() {
        XCTAssertEqual(CollectionStats.favoritePieceCount(from: [300, 500, 1000]), 500)
    }

    func testFormatHours() {
        XCTAssertEqual(CollectionStats.formatHours(fromMinutes: 0), "0 hours")
        XCTAssertEqual(CollectionStats.formatHours(fromMinutes: 45), "45 minutes")
        XCTAssertEqual(CollectionStats.formatHours(fromMinutes: 90), "1.5 hours")
        XCTAssertEqual(CollectionStats.formatHours(fromMinutes: 8520), "142 hours")
    }

    func testInProgressExcludedFromBacklogAndCompletedCounts() {
        let todo = makePuzzle(name: "Shelf", pieces: 500, status: .todo)
        let active = makePuzzle(name: "Table", pieces: 300, status: .inProgress)
        let done = makePuzzle(name: "Done", pieces: 1000, status: .completed)
        done.completionDate = referenceDate

        let stats = CollectionStats.compute(from: [todo, active, done], calendar: calendar, now: referenceDate)

        XCTAssertEqual(stats.backlogCount, 1)
        XCTAssertEqual(stats.completedCount, 1)
        XCTAssertEqual(stats.totalCount, 3)
        XCTAssertEqual(stats.inProgressCount, 1)
    }

    func testComputeCountsMissingPieces() {
        let flagged = makePuzzle(name: "Thrift", pieces: 500, status: .todo)
        flagged.hasMissingPieces = true
        let clean = makePuzzle(name: "New", pieces: 1000, status: .todo)

        let stats = CollectionStats.compute(from: [flagged, clean], calendar: calendar, now: referenceDate)

        XCTAssertEqual(stats.missingPiecesCount, 1)
        XCTAssertEqual(stats.totalCount, 2)
    }

    func testComputeTopTags() {
        let first = makePuzzle(name: "A", pieces: 500, status: .todo)
        first.tags = ["Cozy", "Winter"]
        let second = makePuzzle(name: "B", pieces: 500, status: .todo)
        second.tags = ["cozy"]

        let stats = CollectionStats.compute(from: [first, second], calendar: calendar, now: referenceDate)

        XCTAssertEqual(stats.topTags.count, 2)
        XCTAssertEqual(stats.topTags.first?.name, "Cozy")
        XCTAssertEqual(stats.topTags.first?.count, 2)
    }

    func testCompletionsFilterByMonthAndYear() {
        let thisMonth = makePuzzle(name: "June", pieces: 500, status: .completed)
        thisMonth.completionDate = referenceDate

        let lastYear = makePuzzle(name: "Old", pieces: 500, status: .completed)
        lastYear.completionDate = calendar.date(from: DateComponents(year: 2024, month: 12, day: 1))!

        let stats = CollectionStats.compute(
            from: [thisMonth, lastYear],
            calendar: calendar,
            now: referenceDate
        )

        XCTAssertEqual(stats.completionsThisMonth, 1)
        XCTAssertEqual(stats.completionsThisYear, 1)
        XCTAssertEqual(stats.completedCount, 2)
    }

    func testComputeAverageDaysToComplete() {
        let completed = makePuzzle(name: "Done", pieces: 500, status: .completed)
        completed.startDate = calendar.date(byAdding: .day, value: -4, to: referenceDate)!
        completed.completionDate = referenceDate

        let stats = CollectionStats.compute(from: [completed], calendar: calendar, now: referenceDate)
        XCTAssertEqual(stats.averageDaysToComplete, 4)
        XCTAssertEqual(stats.formattedAverageDaysToComplete, "About 4 days")
    }

    func testComputeWishlistAndAbandonedCounts() {
        let wishlist = makePuzzle(name: "Want", pieces: 500, status: .wishlist)
        let abandoned = makePuzzle(name: "Quit", pieces: 500, status: .abandoned)

        let stats = CollectionStats.compute(from: [wishlist, abandoned], calendar: calendar, now: referenceDate)
        XCTAssertEqual(stats.wishlistCount, 1)
        XCTAssertEqual(stats.abandonedCount, 1)
    }

    func testComputeTopPurchaseLocations() {
        let first = makePuzzle(name: "A", pieces: 500, status: .todo)
        first.purchaseLocation = "Goodwill"
        let second = makePuzzle(name: "B", pieces: 500, status: .todo)
        second.purchaseLocation = "Goodwill"
        let third = makePuzzle(name: "C", pieces: 500, status: .todo)
        third.purchaseLocation = "Amazon"

        let stats = CollectionStats.compute(from: [first, second, third], calendar: calendar, now: referenceDate)
        XCTAssertEqual(stats.topPurchaseLocations.first, "Goodwill")
    }

    // MARK: - Helpers

    private func makePuzzle(
        name: String,
        pieces: Int,
        status: Puzzle.Status,
        rating: Puzzle.Rating = .none
    ) -> Puzzle {
        Puzzle(
            name: name,
            pieces: pieces,
            rating: rating,
            difficulty: .none,
            estimatedTimeSpent: nil,
            completionDate: Date(),
            status: status
        )
    }
}
