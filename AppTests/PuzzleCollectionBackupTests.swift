//
//  PuzzleCollectionBackupTests.swift
//  Puzzle BuddyTests
//

import SwiftData
import UIKit
import XCTest
@testable import Puzzle_Buddy

final class PuzzleCollectionBackupTests: XCTestCase {
    // MARK: - JSON importer

    func testImporterAcceptsSparseBackupMissingOptionalFields() throws {
        let data = try loadFixture(named: "backup-sparse-optional-fields", extension: "json")
        let puzzles = try PuzzleCollectionJSONImporter.puzzles(from: data)

        XCTAssertEqual(puzzles.count, 2)

        let completed = try XCTUnwrap(puzzles.first { $0.name == "Sparse Sunrise" })
        XCTAssertEqual(completed.id, UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"))
        XCTAssertEqual(completed.source, "Galison")
        XCTAssertEqual(completed.status, .completed)
        XCTAssertEqual(completed.puzzleShape, .none)
        XCTAssertEqual(completed.cutType, .none)
        XCTAssertNil(completed.purchasePrice)
        XCTAssertEqual(completed.timesCompleted, 1)
        XCTAssertEqual(completed.completions.count, 1)
        XCTAssertTrue(completed.photos.isEmpty)
        XCTAssertEqual(completed.tags, ["landscape"])

        let todo = try XCTUnwrap(puzzles.first { $0.name == "Minimal Row" })
        XCTAssertEqual(todo.status, .todo)
        XCTAssertEqual(todo.progressPercent, 0)
    }

    func testImporterRejectsNewerBackupFormatVersion() {
        let json = """
        {"backupFormatVersion":99,"puzzles":[{"name":"Future","status":"To-Do","rating":0,"difficulty":"0","completionDate":"2024-01-01T00:00:00Z","puzzleType":"None","material":"None","disposition":"None","progressPercent":0,"timesCompleted":0,"tags":[],"hasMissingPieces":false,"hasImage":false,"photoCount":0,"completions":[]}]}
        """
        XCTAssertThrowsError(try PuzzleCollectionJSONImporter.puzzles(from: Data(json.utf8))) { error in
            guard case PuzzleCollectionJSONImportError.unsupportedFormatVersion(99) = error else {
                return XCTFail("Expected unsupportedFormatVersion, got \(error)")
            }
        }
    }

    func testImporterDecodesCurrentVersionExport() throws {
        var puzzle = makeRichPuzzle()
        let data = try PuzzleCollectionExporter.jsonData(from: [puzzle])
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(json?["backupFormatVersion"] as? Int, PuzzleCollectionBackupFormat.currentVersion)

        let restored = try PuzzleCollectionJSONImporter.puzzles(from: data)
        XCTAssertEqual(restored.count, 1)
        assertPuzzlesEqual(restored[0], puzzle)
    }

    func testExporterEmbedsPhotosAsBase64() throws {
        var puzzle = Puzzle.fixture(name: "With photo", pieces: 100)
        puzzle.photos = [PuzzlePhoto(sortOrder: 0, image: testImage())]

        let data = try PuzzleCollectionExporter.jsonData(from: [puzzle])
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let records = try XCTUnwrap(json?["puzzles"] as? [[String: Any]])
        let photos = try XCTUnwrap(records.first?["photos"] as? [[String: Any]])
        XCTAssertEqual(photos.count, 1)
        XCTAssertNotNil(photos.first?["imageDataBase64"] as? String)
    }

    func testFullJSONRoundTripPreservesCollection() throws {
        let originals = [makeRichPuzzle(), makeCompletedWithHistory()]
        let data = try PuzzleCollectionExporter.jsonData(from: originals)
        let restored = try PuzzleCollectionJSONImporter.puzzles(from: data)

        XCTAssertEqual(restored.count, originals.count)
        for original in originals {
            let match = try XCTUnwrap(restored.first { $0.id == original.id })
            assertPuzzlesEqual(match, original)
        }
    }

    // MARK: - Store restore

    @MainActor
    func testStoreReplaceAllRestoreRoundTrip() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let store = PuzzleStore(modelContext: context)

        var puzzle = makeRichPuzzle()
        try store.add(puzzle: puzzle)
        XCTAssertEqual(store.puzzles.count, 1)

        let backup = try PuzzleCollectionExporter.jsonData(from: [puzzle])
        try store.clearAllPuzzles()
        XCTAssertTrue(store.puzzles.isEmpty)

        let incoming = try PuzzleCollectionJSONImporter.puzzles(from: backup)
        let summary = try store.importBackup(incoming, policy: .replaceAll)

        XCTAssertEqual(summary.imported, 1)
        XCTAssertEqual(store.puzzles.count, 1)
        assertPuzzlesEqual(store.puzzles[0], puzzle)
    }

    @MainActor
    func testStoreMergeSkipsExistingUUID() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let store = PuzzleStore(modelContext: context)

        var existing = makeRichPuzzle()
        try store.add(puzzle: existing)
        let originalNotes = existing.notes

        var updated = makeRichPuzzle()
        updated.id = existing.id
        updated.notes = "Updated in backup"
        updated.purchasePrice = 99.99
        let backup = try PuzzleCollectionExporter.jsonData(from: [updated])

        let incoming = try PuzzleCollectionJSONImporter.puzzles(from: backup)
        let summary = try store.importBackup(incoming, policy: .mergeSkipExistingIDs)

        XCTAssertEqual(summary.imported, 0)
        XCTAssertEqual(summary.skippedExisting, 1)
        XCTAssertEqual(store.puzzles.first?.notes, originalNotes)
        XCTAssertNotEqual(store.puzzles.first?.purchasePrice, 99.99)
    }

    @MainActor
    func testStoreRestorePreservesPhotosAndCompletions() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let store = PuzzleStore(modelContext: context)

        let puzzle = makeCompletedWithHistory()
        let backup = try PuzzleCollectionExporter.jsonData(from: [puzzle])
        let incoming = try PuzzleCollectionJSONImporter.puzzles(from: backup)
        let summary = try store.importBackup(incoming, policy: .replaceAll)

        XCTAssertEqual(summary.imported, 1)
        let loaded = try XCTUnwrap(store.puzzles.first)
        XCTAssertEqual(loaded.photos.count, 1)
        XCTAssertEqual(loaded.completions.count, 2)
        XCTAssertEqual(loaded.timesCompleted, 2)
        XCTAssertNotNil(loaded.coverImage)
    }

    @MainActor
    func testSparseBackupImportsIntoEmptyStore() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let store = PuzzleStore(modelContext: context)

        let data = try loadFixture(named: "backup-sparse-optional-fields", extension: "json")
        let incoming = try PuzzleCollectionJSONImporter.puzzles(from: data)
        let summary = try store.importBackup(incoming, policy: .mergeSkipExistingIDs)

        XCTAssertEqual(summary.imported, 2)
        XCTAssertEqual(store.puzzles.count, 2)
        let completed = try XCTUnwrap(store.puzzles.first { $0.name == "Sparse Sunrise" })
        XCTAssertEqual(completed.completions.count, 1)
    }

    // MARK: - Helpers

    private func makeRichPuzzle() -> Puzzle {
        var puzzle = Puzzle.fixture(name: "Alpine Trail", pieces: 1000, rating: .four, difficulty: .three)
        puzzle.source = "Ravensburger"
        puzzle.barcode = "4005556197523"
        puzzle.status = .inProgress
        puzzle.progressPercent = 40
        puzzle.purchasePrice = 18.50
        puzzle.purchaseCurrencyCode = "USD"
        puzzle.puzzleShape = .rectangular
        puzzle.cutType = .grid
        puzzle.dimensionsText = "27 × 20 in"
        puzzle.notes = "Thrift find"
        puzzle.tags = ["mountains", "winter"]
        puzzle.photos = [
            PuzzlePhoto(sortOrder: 0, image: testImage(color: .systemTeal)),
            PuzzlePhoto(sortOrder: 1, image: testImage(color: .systemIndigo))
        ]
        return puzzle
    }

    private func makeCompletedWithHistory() -> Puzzle {
        var puzzle = Puzzle.fixture(name: "Harbor Lights", pieces: 750, rating: .five)
        puzzle.status = .completed
        puzzle.timesCompleted = 2
        puzzle.photos = [PuzzlePhoto(sortOrder: 0, image: testImage(color: .systemOrange))]
        puzzle.completions = [
            PuzzleCompletion(completionNumber: 1, completedAt: Date(timeIntervalSince1970: 1_000)),
            PuzzleCompletion(completionNumber: 2, completedAt: Date(timeIntervalSince1970: 2_000), rating: 5.0)
        ]
        return puzzle
    }

    private func assertPuzzlesEqual(_ actual: Puzzle, _ expected: Puzzle, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.id, expected.id, file: file, line: line)
        XCTAssertEqual(actual.name, expected.name, file: file, line: line)
        XCTAssertEqual(actual.pieces, expected.pieces, file: file, line: line)
        XCTAssertEqual(actual.status, expected.status, file: file, line: line)
        XCTAssertEqual(actual.rating, expected.rating, file: file, line: line)
        XCTAssertEqual(actual.source, expected.source, file: file, line: line)
        XCTAssertEqual(actual.barcode, expected.barcode, file: file, line: line)
        XCTAssertEqual(actual.purchasePrice, expected.purchasePrice, file: file, line: line)
        XCTAssertEqual(actual.puzzleShape, expected.puzzleShape, file: file, line: line)
        XCTAssertEqual(actual.cutType, expected.cutType, file: file, line: line)
        XCTAssertEqual(actual.dimensionsText, expected.dimensionsText, file: file, line: line)
        XCTAssertEqual(actual.timesCompleted, expected.timesCompleted, file: file, line: line)
        XCTAssertEqual(actual.tags, expected.tags, file: file, line: line)
        XCTAssertEqual(actual.photos.count, expected.photos.count, file: file, line: line)
        XCTAssertEqual(actual.completions.count, expected.completions.count, file: file, line: line)
        XCTAssertNotNil(actual.coverImage, file: file, line: line)
    }

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: PuzzleRecord.self, PuzzlePhotoRecord.self, PuzzleCompletionRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func testImage(color: UIColor = .systemTeal) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { ctx in
            color.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }

    private func loadFixture(named name: String, extension ext: String) throws -> Data {
        let bundle = Bundle(for: PuzzleCollectionBackupTests.self)
        guard let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Fixtures")
            ?? bundle.url(forResource: name, withExtension: ext) else {
            throw PuzzleCollectionJSONImportError.emptyFile
        }
        return try Data(contentsOf: url)
    }
}
