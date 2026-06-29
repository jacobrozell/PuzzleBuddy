//
//  PuzzleExpandedFeatureTests.swift
//  Puzzle BuddyTests
//

import SwiftData
import UIKit
import XCTest
@testable import Puzzle_Buddy

@MainActor
final class PuzzleExpandedFeatureTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var store: PuzzleStore!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: PuzzleRecord.self, PuzzlePhotoRecord.self, PuzzleCompletionRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
        store = PuzzleStore(modelContext: context)
    }

    func testPhysicalMetadataRoundTrip() throws {
        var puzzle = Puzzle.fixture(name: "Round grid", pieces: 500)
        puzzle.puzzleShape = .round
        puzzle.cutType = .grid
        puzzle.dimensionsText = "68 × 49 cm"
        puzzle.purchasePrice = 12.99
        puzzle.purchaseCurrencyCode = "USD"

        try store.add(puzzle: puzzle)
        let loaded = try XCTUnwrap(store.puzzles.first)

        XCTAssertEqual(loaded.puzzleShape, .round)
        XCTAssertEqual(loaded.cutType, .grid)
        XCTAssertEqual(loaded.dimensionsText, "68 × 49 cm")
        XCTAssertEqual(loaded.purchasePrice, 12.99)
    }

    func testRedoIncrementsCompletionCount() throws {
        var puzzle = Puzzle.fixture(name: "Repeat", pieces: 300)
        puzzle.status = .completed
        puzzle.completionDate = Date()

        try store.add(puzzle: puzzle)
        var loaded = try XCTUnwrap(store.puzzles.first(where: { $0.name == "Repeat" }))
        XCTAssertEqual(loaded.timesCompleted, 1)

        try store.startRedo(puzzle: loaded)
        loaded = try XCTUnwrap(store.puzzles.first(where: { $0.id == loaded.id }))
        XCTAssertEqual(loaded.status, .inProgress)
        XCTAssertEqual(loaded.timesCompleted, 1)

        loaded.status = .completed
        loaded.completionDate = Date()
        try store.update(puzzle: loaded)
        loaded = try XCTUnwrap(store.puzzles.first(where: { $0.id == loaded.id }))
        XCTAssertEqual(loaded.timesCompleted, 2)
        XCTAssertEqual(loaded.completions.count, 2)
    }

    func testPhotoPersistence() throws {
        var puzzle = Puzzle.fixture(name: "Photos", pieces: 100)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
        puzzle.photos = [
            PuzzlePhoto(sortOrder: 0, image: image),
            PuzzlePhoto(sortOrder: 1, image: image)
        ]

        try store.add(puzzle: puzzle)
        let loaded = try XCTUnwrap(store.puzzles.first)
        XCTAssertEqual(loaded.photos.count, 2)
        XCTAssertNotNil(loaded.coverImage)
    }
}
