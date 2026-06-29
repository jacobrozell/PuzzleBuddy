//
//  PuzzlePreReleaseRemediationTests.swift
//  Puzzle BuddyTests
//

import SwiftData
import XCTest
@testable import PuzzleBuddy

@MainActor
final class PuzzlePreReleaseRemediationTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: PuzzleRecord.self, PuzzlePhotoRecord.self, PuzzleCompletionRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
    }

    override func tearDown() {
        PuzzleStore.forcesNextSaveFailure = false
    }

    // MARK: - Edit copy isolation

    func testEditCopyDiscardLeavesStoredPuzzleUnchanged() throws {
        let store = PuzzleStore(modelContext: context)
        let puzzle = Puzzle.fixture(name: "Original", pieces: 500)
        try store.add(puzzle: puzzle)

        let editCopy = store.puzzles[0].copy()
        editCopy.name = "Edited in form"

        XCTAssertEqual(store.puzzles[0].name, "Original")
        XCTAssertEqual(editCopy.name, "Edited in form")
    }

    func testEditCopySaveReturnsNormalizedStoreCopy() throws {
        let store = PuzzleStore(modelContext: context)
        let puzzle = Puzzle.fixture(name: "Original", pieces: 500)
        try store.add(puzzle: puzzle)

        let editCopy = store.puzzles[0].copy()
        editCopy.pieces = 750
        try store.update(puzzle: editCopy)

        XCTAssertEqual(store.puzzles[0].pieces, 750)
        XCTAssertEqual(store.puzzles[0].name, "Original")
    }

    // MARK: - Atomic replace-all restore

    func testReplaceAllAllInvalidDoesNotWipeCollection() throws {
        let store = PuzzleStore(modelContext: context)
        try store.add(puzzle: Puzzle.fixture(name: "Keep", pieces: 100))

        let blank = Puzzle.fixture(name: "   ", pieces: 200)
        let empty = Puzzle.fixture(name: "", pieces: 300)
        let summary = try store.importBackup([blank, empty], policy: .replaceAll)

        XCTAssertEqual(store.puzzles.count, 1)
        XCTAssertEqual(store.puzzles[0].name, "Keep")
        XCTAssertEqual(summary.imported, 0)
        XCTAssertEqual(summary.skippedInvalid, 2)
    }

    func testReplaceAllClearsWhenBackupHasValidRows() throws {
        let store = PuzzleStore(modelContext: context)
        try store.add(puzzle: Puzzle.fixture(name: "Old", pieces: 100))

        let incoming = Puzzle.fixture(name: "New", pieces: 500)
        let summary = try store.importBackup([incoming], policy: .replaceAll)

        XCTAssertEqual(summary.imported, 1)
        XCTAssertEqual(store.puzzles.count, 1)
        XCTAssertEqual(store.puzzles[0].name, "New")
    }

    // MARK: - Delete / update failures

    func testDeletePropagatesSaveFailure() throws {
        let store = PuzzleStore(modelContext: context)
        try store.add(puzzle: Puzzle.fixture(name: "One", pieces: 100))

        PuzzleStore.forcesNextSaveFailure = true
        XCTAssertThrowsError(try store.delete(at: IndexSet(integer: 0))) { error in
            guard case PuzzleStoreError.saveFailed = error else {
                return XCTFail("Expected saveFailed, got \(error)")
            }
        }
    }

    func testUpdateThrowsRecordNotFoundWhenRowMissing() throws {
        let store = PuzzleStore(modelContext: context)
        let orphan = Puzzle.fixture(name: "Ghost", pieces: 100)

        XCTAssertThrowsError(try store.update(puzzle: orphan)) { error in
            guard case PuzzleStoreError.recordNotFound = error else {
                return XCTFail("Expected recordNotFound, got \(error)")
            }
        }
    }

    // MARK: - JSON import accounting

    func testJSONImportCountsEmptyNameRows() throws {
        let json = """
        {"backupFormatVersion":1,"puzzles":[
          {"name":"Valid","status":"To-Do","rating":0,"difficulty":"0","completionDate":"2024-01-01T00:00:00Z","puzzleType":"None","material":"None","disposition":"None","progressPercent":0,"timesCompleted":0,"tags":[],"hasMissingPieces":false,"hasImage":false,"photoCount":0,"completions":[]},
          {"name":"   ","status":"To-Do","rating":0,"difficulty":"0","completionDate":"2024-01-01T00:00:00Z","puzzleType":"None","material":"None","disposition":"None","progressPercent":0,"timesCompleted":0,"tags":[],"hasMissingPieces":false,"hasImage":false,"photoCount":0,"completions":[]},
          {"name":"Also Valid","status":"To-Do","rating":0,"difficulty":"0","completionDate":"2024-01-01T00:00:00Z","puzzleType":"None","material":"None","disposition":"None","progressPercent":0,"timesCompleted":0,"tags":[],"hasMissingPieces":false,"hasImage":false,"photoCount":0,"completions":[]}
        ]}
        """
        let result = try PuzzleCollectionJSONImporter.parse(from: Data(json.utf8))
        XCTAssertEqual(result.totalRecords, 3)
        XCTAssertEqual(result.skippedInvalid, 1)
        XCTAssertEqual(result.puzzles.count, 2)

        let store = PuzzleStore(modelContext: context)
        let summary = try store.importBackup(
            result.puzzles,
            policy: .mergeSkipExistingIDs,
            preSkippedInvalid: result.skippedInvalid
        )
        XCTAssertEqual(summary.imported + summary.skippedInvalid, result.totalRecords)
    }

    func testSparseMultiCompletionSynthesizesNCompletions() throws {
        let json = """
        {"backupFormatVersion":1,"puzzles":[{"name":"Repeat","status":"Completed","rating":0,"difficulty":"0","completionDate":"2024-01-01T00:00:00Z","puzzleType":"None","material":"None","disposition":"None","progressPercent":100,"timesCompleted":3,"tags":[],"hasMissingPieces":false,"hasImage":false,"photoCount":0,"completions":[]}]}
        """
        let puzzle = try XCTUnwrap(PuzzleCollectionJSONImporter.puzzles(from: Data(json.utf8)).first)
        XCTAssertEqual(puzzle.completions.count, 3)
        XCTAssertEqual(puzzle.completions.map(\.completionNumber), [1, 2, 3])
    }

    // MARK: - Barcode edge cases

    func testNonNormalizableBarcodeDoesNotDuplicateMatchNormalizedBarcode() throws {
        let store = PuzzleStore(modelContext: context)
        let first = Puzzle.fixture(name: "First", pieces: 500)
        first.barcode = "012345678905"
        try store.add(puzzle: first)

        let tooLong = String(repeating: "0", count: 15) + "12345678905"
        XCTAssertNil(store.findPuzzle(matchingBarcode: BarcodeNormalizer.normalize(tooLong)))
        XCTAssertNil(BarcodeNormalizer.normalize(tooLong))
    }

    func testOutOfRangeOptionalDigitsStillRejectedForStorage() throws {
        let store = PuzzleStore(modelContext: context)
        let puzzle = Puzzle.fixture(name: "Long code", pieces: 500)
        puzzle.barcode = BarcodeNormalizer.optionalDigits(from: String(repeating: "9", count: 20))
        try store.add(puzzle: puzzle)
        XCTAssertNil(store.puzzles.first?.barcode)
    }
}
