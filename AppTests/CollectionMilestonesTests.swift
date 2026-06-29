//
//  CollectionMilestonesTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class CollectionMilestonesTests: XCTestCase {
    func testFirstCompletionMilestone() {
        var completed = makePuzzle(name: "Done", status: .completed)
        completed.completionDate = Date()
        let stats = CollectionStats.compute(from: [completed])

        let earned = CollectionMilestones.earned(from: stats)
        XCTAssertTrue(earned.contains(where: { $0.id == "completed_1" }))
    }

    func testNewlyEarnedExcludesAcknowledged() {
        var completed = makePuzzle(name: "Done", status: .completed)
        completed.completionDate = Date()
        let stats = CollectionStats.compute(from: [completed])

        let fresh = CollectionMilestones.newlyEarned(
            stats: stats,
            previouslyAcknowledged: ["completed_1"]
        )
        XCTAssertTrue(fresh.isEmpty)
    }

    func testAcknowledgePersists() {
        CollectionMilestones.acknowledge("completed_10")
        XCTAssertTrue(CollectionMilestones.loadAcknowledged().contains("completed_10"))
    }

    private func makePuzzle(name: String, status: Puzzle.Status) -> Puzzle {
        Puzzle(
            name: name,
            pieces: 500,
            estimatedTimeSpent: nil,
            completionDate: Date(),
            status: status
        )
    }
}
