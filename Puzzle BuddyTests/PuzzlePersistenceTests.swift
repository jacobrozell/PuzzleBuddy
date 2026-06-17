//
//  PuzzlePersistenceTests.swift
//  Puzzle BuddyTests
//

import SwiftData
import UIKit
import XCTest
@testable import Puzzle_Buddy

@MainActor
final class PuzzlePersistenceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: PuzzleRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
    }

    func testPuzzleRecordRoundTrip() throws {
        let puzzle = Puzzle.fixture(name: "Galaxy", pieces: 750, rating: .fourHalf, difficulty: .three)
        puzzle.status = .completed
        puzzle.estimatedTimeSpent = Puzzle.PuzzleTime(hours: 3, minutes: 15)

        let record = PuzzleRecord(from: puzzle)
        context.insert(record)
        try context.save()

        let restored = record.toPuzzle()
        XCTAssertEqual(restored.id, puzzle.id)
        XCTAssertEqual(restored.name, "Galaxy")
        XCTAssertEqual(restored.pieces, 750)
        XCTAssertEqual(restored.rating, .fourHalf)
        XCTAssertEqual(restored.difficulty, .three)
        XCTAssertEqual(restored.status, .completed)
        XCTAssertEqual(restored.estimatedTimeSpent?.toName(), "3hr:15min")
    }

    func testPuzzleRecordPersistsMissingPiecesAndNotes() throws {
        let puzzle = Puzzle.fixture(name: "Thrift", pieces: 500)
        puzzle.hasMissingPieces = true
        puzzle.notes = "Missing corner piece"
        puzzle.source = "Gift from Mom"
        puzzle.progressPercent = 35
        puzzle.isDemo = true
        puzzle.barcode = "4006381333931"

        let record = PuzzleRecord(from: puzzle)
        context.insert(record)
        try context.save()

        let restored = record.toPuzzle()
        XCTAssertTrue(restored.hasMissingPieces)
        XCTAssertEqual(restored.notes, "Missing corner piece")
        XCTAssertEqual(restored.source, "Gift from Mom")
        XCTAssertEqual(restored.progressPercent, 35)
        XCTAssertTrue(restored.isDemo)
        XCTAssertEqual(restored.barcode, "4006381333931")
    }

    func testPuzzleRecordPersistsInProgressStatus() throws {
        let puzzle = Puzzle.fixture(name: "Tabletop", pieces: 300)
        puzzle.status = .inProgress

        let record = PuzzleRecord(from: puzzle)
        context.insert(record)
        try context.save()

        let restored = record.toPuzzle()
        XCTAssertEqual(restored.status, .inProgress)
        XCTAssertEqual(record.status, Puzzle.Status.inProgress.rawValue)
    }

    func testPuzzleStorePersistsLocally() async throws {
        let store = PuzzleStore(modelContext: context)
        let puzzle = Puzzle.fixture(name: "Sunset", pieces: 500)
        try store.add(puzzle: puzzle)

        let reloaded = PuzzleStore(modelContext: context)
        await reloaded.fetchPuzzles()

        XCTAssertEqual(reloaded.puzzles.count, 1)
        XCTAssertEqual(reloaded.puzzles.first?.name, "Sunset")
    }

    func testPuzzleRecordApplyUpdatesExistingRecord() {
        let record = PuzzleRecord(from: Puzzle.fixture(name: "Before", pieces: 100))
        let updated = Puzzle.fixture(name: "After", pieces: 500, rating: .four, difficulty: .two)
        updated.status = .completed

        record.apply(from: updated)

        XCTAssertEqual(record.name, "After")
        XCTAssertEqual(record.pieces, 500)
        XCTAssertEqual(record.rating, Puzzle.Rating.four.rawValue)
        XCTAssertEqual(record.difficulty, Puzzle.Difficulty.two.rawValue)
        XCTAssertEqual(record.status, Puzzle.Status.completed.rawValue)
    }

    func testPuzzleRecordImageRoundTrip() {
        let puzzle = Puzzle.fixture(name: "Photo", pieces: 250)
        puzzle.image = makeTestImage()

        let record = PuzzleRecord(from: puzzle)
        let restored = record.toPuzzle()

        XCTAssertNotNil(record.imageData)
        XCTAssertNotNil(restored.image)
        XCTAssertGreaterThan(restored.image?.size.width ?? 0, 0)
        XCTAssertGreaterThan(restored.image?.size.height ?? 0, 0)
    }

    private func makeTestImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        return renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }
}
