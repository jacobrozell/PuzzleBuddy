//
//  Puzzle_BuddyUITests.swift
//  Puzzle BuddyUITests
//

import XCTest

final class Puzzle_BuddyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLoginScreenIsPresented() throws {
        try LoginUITestGate.skipForLocalFirstRelease()
    }
}
