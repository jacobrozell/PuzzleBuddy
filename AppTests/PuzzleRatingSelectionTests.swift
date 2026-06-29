//
//  PuzzleRatingSelectionTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class PuzzleRatingSelectionTests: XCTestCase {
    func testLeftTapOnFirstStarClearsRating() {
        XCTAssertEqual(PuzzleRatingSelection.rating(forStar: 1, side: .left), .none)
    }

    func testRightTapOnStarSetsFullRating() {
        XCTAssertEqual(PuzzleRatingSelection.rating(forStar: 3, side: .right), .three)
        XCTAssertEqual(PuzzleRatingSelection.rating(forStar: 5, side: .right), .five)
    }

    func testLeftTapOnStarSetsHalfStep() {
        XCTAssertEqual(PuzzleRatingSelection.rating(forStar: 3, side: .left), .twoHalf)
        XCTAssertEqual(PuzzleRatingSelection.rating(forStar: 5, side: .left), .fourHalf)
    }

    func testIncrementStepsThroughHalfStars() {
        XCTAssertEqual(PuzzleRatingSelection.increment(.none), .one)
        XCTAssertEqual(PuzzleRatingSelection.increment(.one), .oneHalf)
        XCTAssertEqual(PuzzleRatingSelection.increment(.fourHalf), .five)
        XCTAssertEqual(PuzzleRatingSelection.increment(.five), .five)
    }

    func testDecrementStepsThroughHalfStars() {
        XCTAssertEqual(PuzzleRatingSelection.decrement(.five), .fourHalf)
        XCTAssertEqual(PuzzleRatingSelection.decrement(.one), .none)
        XCTAssertEqual(PuzzleRatingSelection.decrement(.none), .none)
    }
}
