//
//  PuzzleReviewFixTests.swift
//  Puzzle BuddyTests
//

import SwiftData
import XCTest
@testable import PuzzleBuddy

@MainActor
final class PuzzleReviewFixTests: XCTestCase {
    func testVersionedInMemoryContainerUsesPlan() throws {
        let container = PuzzleModelContainer.makeInMemoryVersioned()
        let context = container.mainContext
        context.insert(PuzzleRecord(from: Puzzle.fixture(name: "Versioned", pieces: 250)))
        try context.save()
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<PuzzleRecord>()), 1)
    }

    func testUnversionedV1StoreOpensAsV2WithoutWipe() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("puzzle-v1-migrate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("default.store")

        UserDefaults.standard.removeObject(forKey: UserPreferences.storeWasResetNoticePendingKey)

        let puzzleID = UUID()
        let photoID = UUID()
        let firstCompletionID = UUID()
        let secondCompletionID = UUID()
        let firstDate = Date(timeIntervalSince1970: 1_700_000_000)
        let secondDate = Date(timeIntervalSince1970: 1_710_000_000)

        try autoreleasepool {
            let v1 = try PuzzleModelContainer.makeUnversionedV1Persistent(url: storeURL)
            let context = v1.mainContext
            context.insert(
                PuzzleSchemaV1.PuzzleRecord(
                    id: puzzleID,
                    name: "Legacy Bookshop",
                    pieces: 1000,
                    rating: 4,
                    timesCompleted: 2
                )
            )
            context.insert(
                PuzzleSchemaV1.PuzzlePhotoRecord(
                    id: photoID,
                    puzzleID: puzzleID,
                    sortOrder: 0,
                    imageData: Data([0xFF, 0xD8, 0xFF])
                )
            )
            context.insert(
                PuzzleSchemaV1.PuzzleCompletionRecord(
                    id: firstCompletionID,
                    puzzleID: puzzleID,
                    completionNumber: 1,
                    completedAt: firstDate
                )
            )
            context.insert(
                PuzzleSchemaV1.PuzzleCompletionRecord(
                    id: secondCompletionID,
                    puzzleID: puzzleID,
                    completionNumber: 2,
                    completedAt: secondDate
                )
            )
            try context.save()
        }

        let v2 = PuzzleModelContainer.openPersistentStore(at: storeURL)
        let context = v2.mainContext
        let puzzles = try context.fetch(FetchDescriptor<PuzzleRecord>())
        XCTAssertEqual(puzzles.count, 1)
        let puzzle = try XCTUnwrap(puzzles.first)
        XCTAssertEqual(puzzle.id, puzzleID)
        XCTAssertEqual(puzzle.name, "Legacy Bookshop")
        XCTAssertFalse(puzzle.isOnLoan)
        XCTAssertNil(puzzle.dueBackDate)
        XCTAssertNil(puzzle.loanedToFriendID)

        let photos = try context.fetch(FetchDescriptor<PuzzlePhotoRecord>())
        XCTAssertEqual(photos.map(\.id), [photoID])

        let completions = try context.fetch(FetchDescriptor<PuzzleCompletionRecord>())
            .sorted { $0.completionNumber < $1.completionNumber }
        XCTAssertEqual(completions.map(\.id), [firstCompletionID, secondCompletionID])
        XCTAssertEqual(completions.map(\.completedAt), [firstDate, secondDate])
        XCTAssertFalse(UserDefaults.standard.bool(forKey: UserPreferences.storeWasResetNoticePendingKey))
    }

    func testLastCompletionDeleteToInProgressClearsHundredPercent() throws {
        let container = PuzzleModelContainer.makeInMemory()
        let store = PuzzleStore(modelContext: container.mainContext)
        var puzzle = Puzzle.fixture(name: "Last finish", pieces: 500)
        puzzle.status = .completed
        puzzle.progressPercent = 100
        try store.add(puzzle: puzzle)

        let loaded = try XCTUnwrap(store.puzzles.first)
        let completion = try XCTUnwrap(loaded.completions.first)
        try store.deleteCompletion(
            puzzleID: loaded.id,
            completionID: completion.id,
            statusIfRemovingLast: .inProgress
        )

        let refreshed = try XCTUnwrap(store.puzzles.first)
        XCTAssertEqual(refreshed.status, .inProgress)
        XCTAssertLessThan(refreshed.progressPercent, 100)
    }

    func testLastCompletionDeleteToTodo() throws {
        let container = PuzzleModelContainer.makeInMemory()
        let store = PuzzleStore(modelContext: container.mainContext)
        var puzzle = Puzzle.fixture(name: "Back to shelf", pieces: 300)
        puzzle.status = .completed
        try store.add(puzzle: puzzle)

        let loaded = try XCTUnwrap(store.puzzles.first)
        let completion = try XCTUnwrap(loaded.completions.first)
        try store.deleteCompletion(
            puzzleID: loaded.id,
            completionID: completion.id,
            statusIfRemovingLast: .todo
        )

        let refreshed = try XCTUnwrap(store.puzzles.first)
        XCTAssertEqual(refreshed.status, .todo)
        XCTAssertEqual(refreshed.progressPercent, 0)
        XCTAssertTrue(refreshed.completions.isEmpty)
    }

    func testFetchFailureDoesNotZeroTimesCompleted() {
        XCTAssertEqual(
            PuzzleStoreError.completionHistoryUnavailable.errorDescription,
            "Could not load completion history. Your collection was left unchanged."
        )
    }

    func testEditCompletionDateMovesMonthBucket() {
        let calendar = Calendar(identifier: .gregorian)
        let puzzle = Puzzle.fixture(name: "Replay", pieces: 750)
        puzzle.status = .completed
        puzzle.completions = [
            PuzzleCompletion(
                completionNumber: 1,
                completedAt: calendar.date(from: DateComponents(year: 2026, month: 1, day: 10))!
            )
        ]

        XCTAssertEqual(
            CollectionStats.monthlyCompletionCounts(from: [puzzle], year: 2026, calendar: calendar)[0],
            1
        )

        puzzle.completions[0].completedAt = calendar.date(from: DateComponents(year: 2026, month: 3, day: 2))!
        let months = CollectionStats.monthlyCompletionCounts(from: [puzzle], year: 2026, calendar: calendar)
        XCTAssertEqual(months[0], 0)
        XCTAssertEqual(months[2], 1)
    }

    func testSoldDonatedTrashedClearLoan() throws {
        let container = PuzzleModelContainer.makeInMemory()
        let store = PuzzleStore(modelContext: container.mainContext)

        for disposition in [PuzzleDisposition.sold, .donated, .trashed] {
            let puzzle = Puzzle.fixture(name: disposition.rawValue, pieces: 100)
            puzzle.isOnLoan = true
            puzzle.loanedToDisplayName = "Sam"
            try store.add(puzzle: puzzle)
            let saved = try XCTUnwrap(store.puzzles.first { $0.name == disposition.rawValue })
            saved.disposition = disposition
            try store.update(puzzle: saved)
            let refreshed = try XCTUnwrap(store.puzzles.first { $0.name == disposition.rawValue })
            XCTAssertFalse(refreshed.isOnLoan, disposition.rawValue)
            XCTAssertNil(refreshed.loanedToFriendID)
        }
    }

    func testDemoFlagSurvivesJSONExport() throws {
        let puzzle = Puzzle.fixture(name: "Sample", pieces: 250)
        puzzle.isDemo = true
        let data = try PuzzleCollectionExporter.jsonData(from: [puzzle])
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let puzzles = try XCTUnwrap(json?["puzzles"] as? [[String: Any]])
        XCTAssertEqual(puzzles.first?["isDemo"] as? Bool, true)
    }

    func testRemoveDemoKeepsUserLoanFriend() throws {
        let container = PuzzleModelContainer.makeInMemory()
        let store = PuzzleStore(modelContext: container.mainContext)
        try store.loadDemoPuzzles()

        let userPuzzle = Puzzle.fixture(name: "Mine", pieces: 400)
        userPuzzle.isOnLoan = true
        userPuzzle.loanedToDisplayName = "Mom"
        try store.add(puzzle: userPuzzle)

        let friendID = try XCTUnwrap(store.puzzles.first { $0.name == "Mine" }?.loanedToFriendID)
        try store.removeDemoPuzzles()

        XCTAssertEqual(store.puzzles.map(\.name), ["Mine"])
        XCTAssertTrue(store.friends.friends.contains { $0.id == friendID })
    }

    func testFailedPuzzleSaveDoesNotLeaveNewFriend() throws {
        let container = PuzzleModelContainer.makeInMemory()
        let store = PuzzleStore(modelContext: container.mainContext)
        _ = try store.friends.findOrCreate(displayName: "Blake")
        XCTAssertTrue(store.friends.friends.contains { $0.displayName == "Blake" })

        container.mainContext.rollback()
        store.friends.reload()

        XCTAssertFalse(store.friends.friends.contains { $0.displayName == "Blake" })
        let records = try container.mainContext.fetch(FetchDescriptor<FriendRecord>())
        XCTAssertFalse(records.contains { $0.displayName == "Blake" })
    }

    func testDeleteNewestCompletionKeepsRemainingDate() throws {
        let container = PuzzleModelContainer.makeInMemory()
        let store = PuzzleStore(modelContext: container.mainContext)
        var puzzle = Puzzle.fixture(name: "Two finishes", pieces: 400)
        puzzle.status = .completed
        puzzle.completionDate = Date(timeIntervalSince1970: 1_000)
        try store.add(puzzle: puzzle)

        var loaded = try XCTUnwrap(store.puzzles.first)
        try store.startRedo(puzzle: loaded)
        loaded = try XCTUnwrap(store.puzzles.first)
        loaded.status = .completed
        loaded.completionDate = Date(timeIntervalSince1970: 2_000)
        try store.update(puzzle: loaded)

        loaded = try XCTUnwrap(store.puzzles.first)
        let newest = try XCTUnwrap(loaded.completions.max(by: { $0.completedAt < $1.completedAt }))
        try store.deleteCompletion(puzzleID: loaded.id, completionID: newest.id)

        let refreshed = try XCTUnwrap(store.puzzles.first)
        XCTAssertEqual(refreshed.completions.count, 1)
        XCTAssertEqual(refreshed.completionDate, Date(timeIntervalSince1970: 1_000))
    }

    func testEditCompletionDateRenumbersAndPersistsTime() throws {
        let container = PuzzleModelContainer.makeInMemory()
        let store = PuzzleStore(modelContext: container.mainContext)
        var puzzle = Puzzle.fixture(name: "Reorder", pieces: 250)
        puzzle.status = .completed
        puzzle.completionDate = Date(timeIntervalSince1970: 1_000)
        try store.add(puzzle: puzzle)

        var loaded = try XCTUnwrap(store.puzzles.first)
        try store.startRedo(puzzle: loaded)
        loaded = try XCTUnwrap(store.puzzles.first)
        loaded.status = .completed
        loaded.completionDate = Date(timeIntervalSince1970: 2_000)
        try store.update(puzzle: loaded)

        loaded = try XCTUnwrap(store.puzzles.first)
        var older = try XCTUnwrap(loaded.completions.min(by: { $0.completedAt < $1.completedAt }))
        older.completedAt = Date(timeIntervalSince1970: 3_000)
        older.timeSpentHours = 2
        older.timeSpentMinutes = 15
        older.rating = 4
        try store.updateCompletion(puzzleID: loaded.id, completion: older)

        let refreshed = try XCTUnwrap(store.puzzles.first)
        let newest = try XCTUnwrap(refreshed.completions.max(by: { $0.completedAt < $1.completedAt }))
        XCTAssertEqual(newest.id, older.id)
        XCTAssertEqual(newest.completionNumber, 2)
        XCTAssertEqual(newest.timeSpentHours, 2)
        XCTAssertEqual(newest.timeSpentMinutes, 15)
        XCTAssertEqual(newest.rating, 4)
        XCTAssertEqual(refreshed.completionDate, Date(timeIntervalSince1970: 3_000))
    }

    func testJSONExportImportAfterCompletionDelete() throws {
        let container = PuzzleModelContainer.makeInMemory()
        let store = PuzzleStore(modelContext: container.mainContext)
        var puzzle = Puzzle.fixture(name: "Backup", pieces: 300)
        puzzle.status = .completed
        puzzle.completionDate = Date(timeIntervalSince1970: 1_000)
        try store.add(puzzle: puzzle)

        var loaded = try XCTUnwrap(store.puzzles.first)
        try store.startRedo(puzzle: loaded)
        loaded = try XCTUnwrap(store.puzzles.first)
        loaded.status = .completed
        loaded.completionDate = Date(timeIntervalSince1970: 2_000)
        try store.update(puzzle: loaded)

        loaded = try XCTUnwrap(store.puzzles.first)
        let newest = try XCTUnwrap(loaded.completions.max(by: { $0.completedAt < $1.completedAt }))
        try store.deleteCompletion(puzzleID: loaded.id, completionID: newest.id)

        let data = try PuzzleCollectionExporter.jsonData(from: store.puzzles)
        let imported = try PuzzleCollectionJSONImporter.puzzles(from: data)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported.first?.completions.count, 1)
        XCTAssertEqual(imported.first?.completions.first?.completedAt, Date(timeIntervalSince1970: 1_000))
    }
}
