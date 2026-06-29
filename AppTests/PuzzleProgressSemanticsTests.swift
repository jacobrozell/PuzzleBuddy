//
//  PuzzleProgressSemanticsTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class PuzzleProgressSemanticsTests: XCTestCase {
    func testClampedBounds() {
        XCTAssertEqual(PuzzleProgressSemantics.clamped(-5), 0)
        XCTAssertEqual(PuzzleProgressSemantics.clamped(150), 100)
        XCTAssertEqual(PuzzleProgressSemantics.clamped(70), 70)
    }

    func testStatusFromProgress() {
        XCTAssertEqual(PuzzleProgressSemantics.status(for: 0), .todo)
        XCTAssertEqual(PuzzleProgressSemantics.status(for: 45), .inProgress)
        XCTAssertEqual(PuzzleProgressSemantics.status(for: 100), .completed)
    }

    func testProgressFromStatus() {
        XCTAssertEqual(PuzzleProgressSemantics.progress(for: .todo, current: 50), 0)
        XCTAssertEqual(PuzzleProgressSemantics.progress(for: .completed, current: 10), 100)
        XCTAssertEqual(PuzzleProgressSemantics.progress(for: .inProgress, current: 0), 10)
        XCTAssertEqual(PuzzleProgressSemantics.progress(for: .inProgress, current: 70), 70)
    }
}
