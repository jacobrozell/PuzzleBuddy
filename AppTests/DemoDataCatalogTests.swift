//
//  DemoDataCatalogTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class DemoDataCatalogTests: XCTestCase {
    func testMakePuzzlesProducesShowcaseStats() {
        let puzzles = DemoDataCatalog.makePuzzles()
        XCTAssertEqual(puzzles.count, DemoDataCatalog.puzzleCount)

        let stats = CollectionStats.compute(from: puzzles)

        XCTAssertGreaterThanOrEqual(stats.completedCount, 7)
        XCTAssertGreaterThanOrEqual(stats.totalPiecesCompleted, 7_000)
        XCTAssertGreaterThanOrEqual(stats.totalMinutesPuzzling, 3_000)
        XCTAssertGreaterThanOrEqual(stats.completionsThisYear, 7)
        XCTAssertGreaterThanOrEqual(stats.inProgressCount, 2)
        XCTAssertGreaterThanOrEqual(stats.backlogCount, 2)
        XCTAssertEqual(stats.wishlistCount, 1)
        XCTAssertEqual(stats.abandonedCount, 1)
        XCTAssertEqual(stats.missingPiecesCount, 1)
        XCTAssertEqual(stats.replayedPuzzleCount, 1)
        XCTAssertNotNil(stats.averageRating)
        XCTAssertNotNil(stats.averageDaysToComplete)
        XCTAssertNotNil(stats.totalSpend)
        XCTAssertEqual(stats.favoriteBrand, "Ravensburger")
        XCTAssertFalse(stats.paceBuckets.isEmpty)
        XCTAssertFalse(stats.topTags.isEmpty)
        XCTAssertFalse(stats.purchaseLocationCounts.isEmpty)
        XCTAssertGreaterThan(stats.completionsByMonthThisYear.reduce(0, +), 1)
    }

    func testFeaturedPuzzlesKeepMarketingNames() {
        let names = Set(DemoDataCatalog.makePuzzles().map(\.name))
        XCTAssertTrue(names.contains(DemoDataCatalog.duplicateCheckPuzzleName))
        XCTAssertTrue(names.contains(DemoDataCatalog.completedPuzzleName))
    }
}
