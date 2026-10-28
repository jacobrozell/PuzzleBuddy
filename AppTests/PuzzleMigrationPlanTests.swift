//
//  PuzzleMigrationPlanTests.swift
//  Puzzle BuddyTests
//

import CoreData
import SwiftData
import XCTest
@testable import PuzzleBuddy

@MainActor
final class PuzzleMigrationPlanTests: XCTestCase {
    /// Entity version hashes of the live models shipped in 1.1.0 (`PuzzleSchemaV2`).
    private static let shippedV2EntityHashes: [String: String] = [
        "FriendRecord": "tPF98v644f8scZybPqMxP3jUHebis/aeslYcFBEMFIY=",
        "PuzzleCompletionRecord": "AAHET/MkBbPNKC37PMnAxKscvvHvklAgjHEkyOoIXgk=",
        "PuzzlePhotoRecord": "xIAgCbYnSW0Pj759wqa67cHtRKAw6HifturymHG1YOM=",
        "PuzzleRecord": "EgOLlvHAK6VU3LBcgJVFiT8GjqU9iz5WIKXlFBw3Yu0="
    ]

    func testSchemaV1MatchesShippedModels() {
        let modelNames = Set(PuzzleSchemaV1.models.map { String(describing: $0) })
        XCTAssertTrue(modelNames.contains("PuzzleRecord"))
        XCTAssertTrue(modelNames.contains("PuzzlePhotoRecord"))
        XCTAssertTrue(modelNames.contains("PuzzleCompletionRecord"))
        XCTAssertEqual(modelNames.count, 3)
        XCTAssertEqual(PuzzleSchemaV1.versionIdentifier, Schema.Version(1, 0, 0))
    }

    func testSchemaV2AddsFriendRecord() {
        let modelNames = Set(PuzzleSchemaV2.models.map { String(describing: $0) })
        XCTAssertEqual(
            modelNames,
            Set(["FriendRecord", "PuzzleRecord", "PuzzlePhotoRecord", "PuzzleCompletionRecord"])
        )
        XCTAssertEqual(PuzzleSchemaV2.versionIdentifier, Schema.Version(1, 1, 0))
    }

    func testSchemaV2NestedModelsMatchShipped110Fingerprint() throws {
        let hashes = try entityHashes(for: PuzzleSchemaV2.models)
        XCTAssertEqual(hashes, Self.shippedV2EntityHashes)
    }

    func testSchemaV3ChangesOnlyPuzzleRecord() throws {
        XCTAssertEqual(PuzzleSchemaV3.versionIdentifier, Schema.Version(1, 2, 0))
        let v3Hashes = try entityHashes(for: PuzzleSchemaV3.models)
        XCTAssertEqual(Set(v3Hashes.keys), Set(Self.shippedV2EntityHashes.keys))
        XCTAssertNotEqual(v3Hashes["PuzzleRecord"], Self.shippedV2EntityHashes["PuzzleRecord"])
        for name in ["FriendRecord", "PuzzlePhotoRecord", "PuzzleCompletionRecord"] {
            XCTAssertEqual(v3Hashes[name], Self.shippedV2EntityHashes[name], name)
        }
    }

    func testMigrationPlanIncludesLightweightStages() {
        XCTAssertEqual(PuzzleMigrationPlan.schemas.count, 3)
        XCTAssertEqual(PuzzleMigrationPlan.stages.count, 2)
        XCTAssertTrue(PuzzleMigrationPlan.schemas.last == PuzzleSchemaV3.self)
    }

    func testVersionedContainerOpensInMemory() throws {
        let container = PuzzleModelContainer.makeInMemoryVersioned()
        let context = container.mainContext
        context.insert(PuzzleRecord(from: Puzzle.fixture(name: "Migrate", pieces: 500)))
        try context.save()
        let count = try context.fetchCount(FetchDescriptor<PuzzleRecord>())
        XCTAssertEqual(count, 1)
    }

    func testV2StoreOnDiskOpensAsV3WithTimerDefaults() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("puzzle-v2-migrate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("default.store")

        let puzzleID = UUID()
        let friendID = UUID()
        let completionID = UUID()
        let dueBack = Date(timeIntervalSince1970: 1_800_000_000)
        let completedAt = Date(timeIntervalSince1970: 1_700_000_000)

        try autoreleasepool {
            let schema = Schema(versionedSchema: PuzzleSchemaV2.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
            let v2Container = try ModelContainer(for: schema, configurations: [configuration])
            let context = v2Container.mainContext
            context.insert(PuzzleSchemaV2.FriendRecord(id: friendID, displayName: "Sam"))
            context.insert(
                PuzzleSchemaV2.PuzzleRecord(
                    id: puzzleID,
                    name: "Loaned Lighthouse",
                    pieces: 1000,
                    estimatedTimeHours: 2,
                    estimatedTimeMinutes: 15,
                    status: "In-Progress",
                    progressPercent: 40,
                    timesCompleted: 1,
                    isOnLoan: true,
                    loanedToFriendID: friendID,
                    dueBackDate: dueBack
                )
            )
            context.insert(
                PuzzleSchemaV2.PuzzleCompletionRecord(
                    id: completionID,
                    puzzleID: puzzleID,
                    completionNumber: 1,
                    completedAt: completedAt
                )
            )
            try context.save()
        }

        let v3Container = try PuzzleModelContainer.makeVersionedPersistent(url: storeURL)
        let context = v3Container.mainContext
        let record = try XCTUnwrap(try context.fetch(FetchDescriptor<PuzzleRecord>()).first)
        XCTAssertEqual(record.id, puzzleID)
        XCTAssertEqual(record.name, "Loaned Lighthouse")
        XCTAssertEqual(record.status, "In-Progress")
        XCTAssertEqual(record.progressPercent, 40)
        XCTAssertEqual(record.estimatedTimeHours, 2)
        XCTAssertEqual(record.estimatedTimeMinutes, 15)
        XCTAssertTrue(record.isOnLoan)
        XCTAssertEqual(record.loanedToFriendID, friendID)
        XCTAssertEqual(record.dueBackDate, dueBack)
        XCTAssertEqual(record.timerAccumulatedSeconds, 0)
        XCTAssertNil(record.timerRunningSince)

        let friends = try context.fetch(FetchDescriptor<FriendRecord>())
        XCTAssertEqual(friends.map(\.id), [friendID])
        let completions = try context.fetch(FetchDescriptor<PuzzleCompletionRecord>())
        XCTAssertEqual(completions.map(\.id), [completionID])

        record.timerAccumulatedSeconds = 90
        record.timerRunningSince = completedAt
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<PuzzleRecord>()).first?.timerAccumulatedSeconds, 90)
    }

    func testFriendsListFeatureFlagIsOff() {
        XCTAssertFalse(ProductService.isFriendsListEnabled)
    }

    private func entityHashes(for models: [any PersistentModel.Type]) throws -> [String: String] {
        let model = try XCTUnwrap(NSManagedObjectModel.makeManagedObjectModel(for: models))
        return model.entityVersionHashesByName.mapValues { $0.base64EncodedString() }
    }
}
