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

    // MARK: - Physical metadata & price

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
        XCTAssertEqual(loaded.purchaseCurrencyCode, "USD")
    }

    func testPrepareForPersistenceClearsCurrencyWhenPriceRemoved() {
        var puzzle = Puzzle.fixture(name: "Price", pieces: 100)
        puzzle.purchasePrice = 9.99
        puzzle.purchaseCurrencyCode = "USD"
        puzzle.purchasePrice = nil
        puzzle.prepareForPersistence()
        XCTAssertNil(puzzle.purchaseCurrencyCode)
    }

    func testPhysicalMetadataSurvivesStoreReload() async throws {
        var puzzle = Puzzle.fixture(name: "Reload", pieces: 300)
        puzzle.puzzleShape = .square
        puzzle.cutType = .ribbon
        puzzle.dimensionsText = "50 cm"
        try store.add(puzzle: puzzle)
        let puzzleID = puzzle.id

        let reloaded = PuzzleStore(modelContext: context)
        await reloaded.fetchPuzzles()
        let loaded = try XCTUnwrap(reloaded.puzzles.first { $0.id == puzzleID })
        XCTAssertEqual(loaded.puzzleShape, .square)
        XCTAssertEqual(loaded.cutType, .ribbon)
    }

    // MARK: - Redo & completions

    func testRedoIncrementsCompletionCount() throws {
        var puzzle = Puzzle.fixture(name: "Repeat", pieces: 300)
        puzzle.status = .completed
        puzzle.completionDate = Date()

        try store.add(puzzle: puzzle)
        var loaded = try XCTUnwrap(store.puzzles.first(where: { $0.name == "Repeat" }))
        XCTAssertEqual(loaded.timesCompleted, 1)
        XCTAssertEqual(loaded.completions.count, 1)

        try store.startRedo(puzzle: loaded)
        loaded = try XCTUnwrap(store.puzzles.first(where: { $0.id == loaded.id }))
        XCTAssertEqual(loaded.status, .inProgress)
        XCTAssertEqual(loaded.progressPercent, 0)
        XCTAssertNotNil(loaded.startDate)
        XCTAssertEqual(loaded.timesCompleted, 1)

        loaded.status = .completed
        loaded.completionDate = Date()
        try store.update(puzzle: loaded)
        loaded = try XCTUnwrap(store.puzzles.first(where: { $0.id == loaded.id }))
        XCTAssertEqual(loaded.timesCompleted, 2)
        XCTAssertEqual(loaded.completions.count, 2)
        XCTAssertEqual(loaded.completions.map(\.completionNumber), [1, 2])
    }

    func testUpdateWithoutStatusChangeDoesNotAddCompletion() throws {
        var puzzle = Puzzle.fixture(name: "Stable", pieces: 200)
        puzzle.status = .completed
        try store.add(puzzle: puzzle)
        var loaded = try XCTUnwrap(store.puzzles.first)
        XCTAssertEqual(loaded.timesCompleted, 1)

        loaded.notes = "Still done"
        try store.update(puzzle: loaded)
        loaded = try XCTUnwrap(store.puzzles.first)
        XCTAssertEqual(loaded.timesCompleted, 1)
        XCTAssertEqual(loaded.completions.count, 1)
    }

    func testStartRedoIgnoresNonCompletedPuzzle() throws {
        var puzzle = Puzzle.fixture(name: "Active", pieces: 200)
        puzzle.status = .inProgress
        try store.add(puzzle: puzzle)
        let loaded = try XCTUnwrap(store.puzzles.first)
        try store.startRedo(puzzle: loaded)
        XCTAssertEqual(store.puzzles.first?.status, .inProgress)
        XCTAssertEqual(store.puzzles.first?.timesCompleted, 0)
    }

    func testCompletionRecordCapturesTimeSpent() throws {
        var puzzle = Puzzle.fixture(name: "Timed", pieces: 500)
        puzzle.status = .completed
        puzzle.estimatedTimeSpent = Puzzle.PuzzleTime(hours: 4, minutes: 15)
        puzzle.rating = .five
        try store.add(puzzle: puzzle)
        let completion = try XCTUnwrap(store.puzzles.first?.completions.first)
        XCTAssertEqual(completion.timeSpentHours, 4)
        XCTAssertEqual(completion.timeSpentMinutes, 15)
        XCTAssertEqual(completion.rating, 5.0)
    }

    // MARK: - Photos

    func testPhotoPersistence() throws {
        var puzzle = Puzzle.fixture(name: "Photos", pieces: 100)
        let image = testImage()
        puzzle.photos = [
            PuzzlePhoto(sortOrder: 0, image: image),
            PuzzlePhoto(sortOrder: 1, image: image)
        ]

        try store.add(puzzle: puzzle)
        let loaded = try XCTUnwrap(store.puzzles.first)
        XCTAssertEqual(loaded.photos.count, 2)
        XCTAssertNotNil(loaded.coverImage)
    }

    func testLegacyImageMigratesToPhotoOnFetch() async throws {
        var puzzle = Puzzle.fixture(name: "Legacy", pieces: 100)
        puzzle.image = testImage()
        let record = PuzzleRecord(from: puzzle)
        context.insert(record)
        try context.save()

        let freshStore = PuzzleStore(modelContext: context)
        await freshStore.fetchPuzzles()
        let loaded = try XCTUnwrap(freshStore.puzzles.first)
        XCTAssertEqual(loaded.photos.count, 1)
        XCTAssertNotNil(loaded.coverImage)
    }

    func testUpdatingPhotosReplacesStoredRecords() throws {
        var puzzle = Puzzle.fixture(name: "Swap", pieces: 100)
        puzzle.photos = [PuzzlePhoto(sortOrder: 0, image: testImage())]
        try store.add(puzzle: puzzle)
        var loaded = try XCTUnwrap(store.puzzles.first)
        let puzzleID = loaded.id

        loaded.photos = [
            PuzzlePhoto(sortOrder: 0, image: testImage()),
            PuzzlePhoto(sortOrder: 1, image: testImage())
        ]
        try store.update(puzzle: loaded)

        let photoRecords = try context.fetch(FetchDescriptor<PuzzlePhotoRecord>())
        XCTAssertEqual(photoRecords.filter { $0.puzzleID == puzzleID }.count, 2)
        XCTAssertEqual(store.puzzles.first?.photos.count, 2)
    }

    func testDeleteRemovesPhotosAndCompletions() throws {
        var puzzle = Puzzle.fixture(name: "Delete me", pieces: 100)
        puzzle.status = .completed
        puzzle.photos = [PuzzlePhoto(sortOrder: 0, image: testImage())]
        try store.add(puzzle: puzzle)
        let puzzleID = try XCTUnwrap(store.puzzles.first?.id)

        store.delete(at: IndexSet(integer: 0))

        let photos = try context.fetch(FetchDescriptor<PuzzlePhotoRecord>())
        let completions = try context.fetch(FetchDescriptor<PuzzleCompletionRecord>())
        XCTAssertTrue(photos.filter { $0.puzzleID == puzzleID }.isEmpty)
        XCTAssertTrue(completions.filter { $0.puzzleID == puzzleID }.isEmpty)
        XCTAssertTrue(store.puzzles.isEmpty)
    }

    // MARK: - Import path (IPDb CSV → store)

    func testImportPreservesExpandedFieldsFromStorePath() throws {
        var puzzle = Puzzle.fixture(name: "Imported", pieces: 750)
        puzzle.puzzleShape = .rectangular
        puzzle.cutType = .random
        puzzle.dimensionsText = "27 in"
        puzzle.purchasePrice = 7.50
        puzzle.purchaseCurrencyCode = "USD"

        let summary = try store.importPuzzles([puzzle])
        XCTAssertEqual(summary.imported, 1)
        let loaded = try XCTUnwrap(store.puzzles.first { $0.name == "Imported" })
        XCTAssertEqual(loaded.puzzleShape, .rectangular)
        XCTAssertEqual(loaded.purchasePrice, 7.50)
    }

    private func testImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { ctx in
            UIColor.systemOrange.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }
}
