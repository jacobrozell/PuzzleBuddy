//
//  PuzzleMigrationPlanTests.swift
//  Puzzle BuddyTests
//

import SwiftData
import XCTest
@testable import PuzzleBuddy

@MainActor
final class PuzzleMigrationPlanTests: XCTestCase {
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

    func testMigrationPlanIncludesLightweightV1ToV2() {
        XCTAssertEqual(PuzzleMigrationPlan.schemas.count, 2)
        XCTAssertEqual(PuzzleMigrationPlan.stages.count, 1)
    }

    func testVersionedContainerOpensInMemory() throws {
        let container = PuzzleModelContainer.makeInMemory()
        let context = container.mainContext
        context.insert(PuzzleRecord(from: Puzzle.fixture(name: "Migrate", pieces: 500)))
        try context.save()
        let count = try context.fetchCount(FetchDescriptor<PuzzleRecord>())
        XCTAssertEqual(count, 1)
    }

    func testFriendsListFeatureFlagIsOff() {
        XCTAssertFalse(ProductService.isFriendsListEnabled)
    }
}
