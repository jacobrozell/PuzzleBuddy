//
//  PuzzleShareTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class PuzzleShareTests: XCTestCase {
    func testGridDimensions() {
        XCTAssertEqual(PuzzleCollectionCollageLayout.gridDimensions(for: 1).columns, 1)
        XCTAssertEqual(PuzzleCollectionCollageLayout.gridDimensions(for: 4).columns, 2)
        XCTAssertEqual(PuzzleCollectionCollageLayout.gridDimensions(for: 8).columns, 3)
        XCTAssertEqual(PuzzleCollectionCollageLayout.gridDimensions(for: 20).displayed, 12)
    }

    func testShareSummaryIncludesCounts() {
        let puzzles = [
            makePuzzle(name: "A", status: .completed),
            makePuzzle(name: "B", status: .inProgress),
            makePuzzle(name: "C", status: .todo)
        ]
        let stats = CollectionStats.compute(from: puzzles)
        let summary = PuzzleShareSummary.make(from: stats, puzzles: puzzles)

        XCTAssertTrue(summary.contains("3 puzzles"))
        XCTAssertTrue(summary.contains("1 completed"))
        XCTAssertTrue(summary.contains("1 in progress"))
        XCTAssertTrue(summary.contains("A"))
    }

    func testShareFooterLabelUsesMarketingSite() {
        XCTAssertEqual(AppLinks.shareFooterLabel, "jacobrozell.github.io/PuzzleBuddy")
    }

    func testCollageRendererProducesImage() {
        let puzzles = [
            makePuzzle(name: "Sunset", status: .completed),
            makePuzzle(name: "Harbor", status: .inProgress)
        ]
        let stats = CollectionStats.compute(from: puzzles)
        let image = PuzzleCollectionCollageRenderer.render(puzzles: puzzles, stats: stats)

        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }

    @MainActor
    func testMakePayloadReturnsNilForEmptyCollection() {
        XCTAssertNil(PuzzleCollectionShare.makePayload(puzzles: []))
    }

    @MainActor
    func testMakePayloadBuildsImageAndCaption() {
        let payload = PuzzleCollectionShare.makePayload(puzzles: [
            makePuzzle(name: "Galaxy", status: .completed)
        ])

        XCTAssertNotNil(payload)
        XCTAssertFalse(payload?.caption.isEmpty ?? true)
        XCTAssertGreaterThan(payload?.image.size.width ?? 0, 0)
    }

    private func makePuzzle(name: String, status: Puzzle.Status) -> Puzzle {
        let puzzle = Puzzle.fixture(name: name, pieces: 500)
        puzzle.status = status
        return puzzle
    }
}
