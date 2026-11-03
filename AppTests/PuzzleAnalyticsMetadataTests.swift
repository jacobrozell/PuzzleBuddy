//
//  PuzzleAnalyticsMetadataTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class PuzzleAnalyticsMetadataTests: XCTestCase {
    func testPieceCountBuckets() {
        XCTAssertEqual(PuzzleAnalyticsMetadata.pieceCountBucket(for: nil), "unknown")
        XCTAssertEqual(PuzzleAnalyticsMetadata.pieceCountBucket(for: 500), "under_500")
        XCTAssertEqual(PuzzleAnalyticsMetadata.pieceCountBucket(for: 600), "500")
        XCTAssertEqual(PuzzleAnalyticsMetadata.pieceCountBucket(for: 1000), "1000")
        XCTAssertEqual(PuzzleAnalyticsMetadata.pieceCountBucket(for: 2000), "1500_plus")
    }

    func testRatingBuckets() {
        XCTAssertEqual(PuzzleAnalyticsMetadata.ratingBucket(for: .none), "none")
        XCTAssertEqual(PuzzleAnalyticsMetadata.ratingBucket(for: .twoHalf), "1_2")
        XCTAssertEqual(PuzzleAnalyticsMetadata.ratingBucket(for: .three), "3")
        XCTAssertEqual(PuzzleAnalyticsMetadata.ratingBucket(for: .five), "5")
    }

    func testCollectionSizeBuckets() {
        XCTAssertEqual(PuzzleAnalyticsMetadata.collectionSizeBucket(0), "0")
        XCTAssertEqual(PuzzleAnalyticsMetadata.collectionSizeBucket(1), "1")
        XCTAssertEqual(PuzzleAnalyticsMetadata.collectionSizeBucket(4), "2_5")
        XCTAssertEqual(PuzzleAnalyticsMetadata.collectionSizeBucket(12), "6_20")
        XCTAssertEqual(PuzzleAnalyticsMetadata.collectionSizeBucket(30), "21_50")
        XCTAssertEqual(PuzzleAnalyticsMetadata.collectionSizeBucket(80), "51_plus")
    }

    func testCompletedCountBuckets() {
        XCTAssertEqual(PuzzleAnalyticsMetadata.completedCountBucket(0), "0")
        XCTAssertEqual(PuzzleAnalyticsMetadata.completedCountBucket(1), "1")
        XCTAssertEqual(PuzzleAnalyticsMetadata.completedCountBucket(3), "2_5")
        XCTAssertEqual(PuzzleAnalyticsMetadata.completedCountBucket(9), "6_plus")
    }

    func testDaysSinceLastOpenBuckets() {
        XCTAssertEqual(PuzzleAnalyticsMetadata.daysSinceLastOpenBucket(days: nil), "first_open")
        XCTAssertEqual(PuzzleAnalyticsMetadata.daysSinceLastOpenBucket(days: 0), "0")
        XCTAssertEqual(PuzzleAnalyticsMetadata.daysSinceLastOpenBucket(days: 1), "1")
        XCTAssertEqual(PuzzleAnalyticsMetadata.daysSinceLastOpenBucket(days: 5), "2_7")
        XCTAssertEqual(PuzzleAnalyticsMetadata.daysSinceLastOpenBucket(days: 14), "8_30")
        XCTAssertEqual(PuzzleAnalyticsMetadata.daysSinceLastOpenBucket(days: 60), "31_plus")
    }

    func testCollectionSnapshotMetadata() {
        let todo = Puzzle.fixture(name: "Todo", pieces: 500)
        todo.status = .todo
        let done = Puzzle.fixture(name: "Done", pieces: 1000)
        done.status = .completed
        let meta = PuzzleAnalyticsMetadata.collectionSnapshotMetadata(for: [todo, done])
        XCTAssertEqual(meta["puzzle_count"], "2")
        XCTAssertEqual(meta["count_todo"], "1")
        XCTAssertEqual(meta["count_completed"], "1")
        XCTAssertEqual(meta["count_wishlist"], "0")
        XCTAssertEqual(meta["collection_size_bucket"], "2_5")
        XCTAssertEqual(meta["completed_count_bucket"], "1")
    }

    func testCompletionMetadataIncludesEnrichedFields() {
        var puzzle = Puzzle.fixture(name: "Sample", pieces: 1000)
        puzzle.status = .completed
        puzzle.rating = .four
        puzzle.difficulty = .three
        puzzle.puzzleType = .landscape
        puzzle.hasMissingPieces = true

        let metadata = PuzzleAnalyticsMetadata.completionMetadata(for: puzzle, completionNumber: 2)

        XCTAssertEqual(metadata["completion_number"], "2")
        XCTAssertEqual(metadata["piece_count_bucket"], "1000")
        XCTAssertEqual(metadata["puzzle_type"], "Landscape")
        XCTAssertEqual(metadata["difficulty"], "3")
        XCTAssertEqual(metadata["rating_bucket"], "4")
        XCTAssertEqual(metadata["has_missing_pieces"], "true")
    }
}
