//
//  CollectionMilestonesTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class CollectionMilestonesTests: XCTestCase {
    func testFirstCompletionMilestone() {
        let completed = makePuzzle(name: "Done", status: .completed)
        completed.completionDate = Date()
        let stats = CollectionStats.compute(from: [completed])

        let earned = CollectionMilestones.earned(from: stats)
        XCTAssertTrue(earned.contains(where: { $0.id == "completed_1" }))
    }

    func testNewlyEarnedExcludesAcknowledged() {
        let completed = makePuzzle(name: "Done", status: .completed)
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

    func testCompletedThresholds() {
        let stats10 = CollectionStats.compute(from: completedPuzzles(count: 10))
        XCTAssertTrue(CollectionMilestones.earned(from: stats10).contains { $0.id == "completed_10" })

        let stats50 = CollectionStats.compute(from: completedPuzzles(count: 50))
        XCTAssertTrue(CollectionMilestones.earned(from: stats50).contains { $0.id == "completed_50" })
    }

    func testPiecesAndHoursThresholds() {
        let puzzles = completedPuzzles(count: 1, piecesEach: 10_000)
        var timed = puzzles[0]
        timed.estimatedTimeSpent = Puzzle.PuzzleTime(hours: 100, minutes: 0)
        let stats = CollectionStats.compute(from: [timed])
        let earned = CollectionMilestones.earned(from: stats)
        XCTAssertTrue(earned.contains { $0.id == "pieces_10000" })
        XCTAssertTrue(earned.contains { $0.id == "hours_100" })
    }

    func testYearCompletionThreshold() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let puzzles = (1...12).map { month -> Puzzle in
            let puzzle = makePuzzle(name: "P\(month)", status: .completed)
            puzzle.completionDate = calendar.date(from: DateComponents(year: 2026, month: month, day: 15))!
            return puzzle
        }
        let stats = CollectionStats.compute(from: puzzles, calendar: calendar, now: now)
        XCTAssertTrue(CollectionMilestones.earned(from: stats).contains { $0.id == "year_completions_12" })
    }

    func testExcludingDemoDoesNotChangeThresholdIDs() {
        let demo = makePuzzle(name: "Demo", status: .completed)
        demo.isDemo = true
        let stats = CollectionStats.compute(from: [demo])
        XCTAssertTrue(CollectionMilestones.earned(from: stats, excludingDemo: true).contains { $0.id == "completed_1" })
    }

    private func completedPuzzles(count: Int, piecesEach: Int = 500) -> [Puzzle] {
        (0..<count).map { index in
            let puzzle = makePuzzle(name: "Done \(index)", status: .completed)
            puzzle.pieces = piecesEach
            puzzle.completionDate = Date()
            return puzzle
        }
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
