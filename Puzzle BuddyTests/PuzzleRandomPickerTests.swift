//
//  PuzzleRandomPickerTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class PuzzleRandomPickerTests: XCTestCase {
    func testEligibleExcludesWishlistAbandonedAndCompleted() {
        let wishlist = makePuzzle(name: "Wish", status: .wishlist)
        let abandoned = makePuzzle(name: "Quit", status: .abandoned)
        let todo = makePuzzle(name: "Shelf", status: .todo)
        let active = makePuzzle(name: "Table", status: .inProgress)
        let done = makePuzzle(name: "Done", status: .completed)
        let eligible = PuzzleRandomPicker.eligible(
            from: [wishlist, todo, active, done, abandoned],
            includeInProgress: false,
            pieceCountFilter: .any,
            tagFilter: nil
        )

        XCTAssertEqual(eligible.map(\.name), ["Shelf"])
    }

    func testEligibleIncludesInProgressWhenRequested() {
        let todo = makePuzzle(name: "Shelf", status: .todo)
        let active = makePuzzle(name: "Table", status: .inProgress)

        let eligible = PuzzleRandomPicker.eligible(
            from: [todo, active],
            includeInProgress: true,
            pieceCountFilter: .any,
            tagFilter: nil
        )

        XCTAssertEqual(Set(eligible.map(\.name)), Set(["Shelf", "Table"]))
    }

    func testEligibleFiltersByTagAndPieceCount() {
        var tagged = makePuzzle(name: "Winter", status: .todo, pieces: 1000)
        tagged.tags = ["cozy"]
        var wrongPieces = makePuzzle(name: "Small", status: .todo, pieces: 300)
        wrongPieces.tags = ["cozy"]

        let eligible = PuzzleRandomPicker.eligible(
            from: [tagged, wrongPieces],
            includeInProgress: false,
            pieceCountFilter: .thousand,
            tagFilter: "cozy"
        )

        XCTAssertEqual(eligible.map(\.name), ["Winter"])
    }

    func testPickReturnsMemberOfPool() {
        let first = makePuzzle(name: "A", status: .todo)
        let second = makePuzzle(name: "B", status: .todo)
        let pool = [first, second]

        let picked = PuzzleRandomPicker.pick(from: pool, excluding: nil)
        XCTAssertTrue(pool.contains(where: { $0.id == picked?.id }))
    }

    func testPickReturnsNilForEmptyPool() {
        XCTAssertNil(PuzzleRandomPicker.pick(from: [], excluding: nil))
    }

    private func makePuzzle(
        name: String,
        status: Puzzle.Status,
        pieces: Int = 500
    ) -> Puzzle {
        Puzzle(
            name: name,
            pieces: pieces,
            estimatedTimeSpent: nil,
            completionDate: Date(),
            status: status
        )
    }
}