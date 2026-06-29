//
//  PuzzleDetailMetricsTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class PuzzleDetailMetricsTests: XCTestCase {
    func testTimeBucketLabels() {
        XCTAssertEqual(PuzzleDetailMetrics.timeBucketLabel(forMinutes: 0), "Quick finish")
        XCTAssertEqual(PuzzleDetailMetrics.timeBucketLabel(forMinutes: 239), "Quick finish")
        XCTAssertEqual(PuzzleDetailMetrics.timeBucketLabel(forMinutes: 240), "Weekend puzzle")
        XCTAssertEqual(PuzzleDetailMetrics.timeBucketLabel(forMinutes: 719), "Weekend puzzle")
        XCTAssertEqual(PuzzleDetailMetrics.timeBucketLabel(forMinutes: 720), "Marathon project")
        XCTAssertEqual(PuzzleDetailMetrics.timeBucketLabel(forMinutes: 2000), "Marathon project")
    }

    func testHoursPer1000Pieces() {
        let time = Puzzle.PuzzleTime(hours: 5, minutes: 0)
        let metrics = PuzzleDetailMetrics.compute(pieces: 1000, time: time)

        XCTAssertEqual(metrics.timeBucketLabel, "Weekend puzzle")
        XCTAssertEqual(metrics.hoursPer1000Pieces, 5.0)
        XCTAssertEqual(metrics.formattedHoursPer1000Pieces, "5 hrs per 1,000 pieces")
    }

    func testHoursPer1000PiecesScalesWithPieceCount() {
        let time = Puzzle.PuzzleTime(hours: 2, minutes: 30)
        let metrics = PuzzleDetailMetrics.compute(pieces: 500, time: time)

        XCTAssertEqual(metrics.hoursPer1000Pieces, 5.0)
    }

    func testComputeWithoutTimeReturnsNoDerivedMetrics() {
        let metrics = PuzzleDetailMetrics.compute(pieces: 1000, time: nil)

        XCTAssertNil(metrics.timeBucketLabel)
        XCTAssertNil(metrics.hoursPer1000Pieces)
    }

    func testComputeWithPartialTimeReturnsNoDerivedMetrics() {
        let partial = Puzzle.PuzzleTime(hours: 2, minutes: nil)
        let metrics = PuzzleDetailMetrics.compute(pieces: 1000, time: partial)

        XCTAssertNil(metrics.timeBucketLabel)
        XCTAssertNil(metrics.hoursPer1000Pieces)
    }

    func testComputeTimeBucketWithoutPieces() {
        let time = Puzzle.PuzzleTime(hours: 1, minutes: 0)
        let metrics = PuzzleDetailMetrics.compute(pieces: nil, time: time)

        XCTAssertEqual(metrics.timeBucketLabel, "Quick finish")
        XCTAssertNil(metrics.hoursPer1000Pieces)
    }

    func testFormattedHoursPer1000UsesMinutesForFastPuzzles() {
        let time = Puzzle.PuzzleTime(hours: 0, minutes: 30)
        let metrics = PuzzleDetailMetrics.compute(pieces: 1000, time: time)

        XCTAssertEqual(metrics.formattedHoursPer1000Pieces, "30 min per 1,000 pieces")
    }
}
