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
