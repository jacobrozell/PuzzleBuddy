//
//  PuzzleRandomPickerTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class PuzzleRandomPickerTests: XCTestCase {
    func testEligibleIncludesOnlyTodoByDefault() {
        let todo = Puzzle.fixture(name: "Shelf", pieces: 500)
        let inProgress = Puzzle.fixture(name: "Active", pieces: 500)
        inProgress.status = .inProgress
        let done = Puzzle.fixture(name: "Done", pieces: 500)
        done.status = .completed
        let wishlist = Puzzle.fixture(name: "Wish", pieces: 500)
        wishlist.status = .wishlist

        let eligible = PuzzleRandomPicker.eligible(
            from: [todo, inProgress, done, wishlist],
            includeInProgress: false,
            pieceCountFilter: .any,
            tagFilter: nil
        )
        XCTAssertEqual(eligible.map(\.name), ["Shelf"])
    }

    func testEligibleIncludesInProgressWhenFlagged() {
        let todo = Puzzle.fixture(name: "Shelf", pieces: 500)
        let inProgress = Puzzle.fixture(name: "Active", pieces: 500)
        inProgress.status = .inProgress

        let eligible = PuzzleRandomPicker.eligible(
            from: [todo, inProgress],
            includeInProgress: true,
            pieceCountFilter: .any,
            tagFilter: nil
        )
        XCTAssertEqual(Set(eligible.map(\.name)), ["Shelf", "Active"])
    }

    func testEligibleRespectsPieceCountFilter() {
        let small = Puzzle.fixture(name: "Small", pieces: 300)
        let big = Puzzle.fixture(name: "Big", pieces: 2000)

        let eligible = PuzzleRandomPicker.eligible(
            from: [small, big],
            includeInProgress: false,
            pieceCountFilter: .atLeast1500,
            tagFilter: nil
        )
        XCTAssertEqual(eligible.map(\.name), ["Big"])
    }

    func testEligibleRespectsTagFilter() {
        let tagged = Puzzle.fixture(name: "Cozy", pieces: 500)
        tagged.tags = ["winter"]
        let plain = Puzzle.fixture(name: "Plain", pieces: 500)

        let eligible = PuzzleRandomPicker.eligible(
            from: [tagged, plain],
            includeInProgress: false,
            pieceCountFilter: .any,
            tagFilter: "Winter"
        )
        XCTAssertEqual(eligible.map(\.name), ["Cozy"])
    }

    func testPickAvoidsPreviousWhenAlternativesExist() {
        let a = Puzzle.fixture(name: "A", pieces: 500)
        let b = Puzzle.fixture(name: "B", pieces: 500)
        var generator = SystemRandomNumberGenerator()
        let next = PuzzleRandomPicker.pick(from: [a, b], excluding: a.id, using: &generator)
        XCTAssertEqual(next?.id, b.id)
    }

    func testPickReturnsNilForEmptyPool() {
        XCTAssertNil(PuzzleRandomPicker.pick(from: [], excluding: nil))
    }

    func testPickFallsBackWhenOnlyOneEligible() {
        let only = Puzzle.fixture(name: "Solo", pieces: 500)
        let next = PuzzleRandomPicker.pick(from: [only], excluding: only.id)
        XCTAssertEqual(next?.id, only.id)
    }
}
