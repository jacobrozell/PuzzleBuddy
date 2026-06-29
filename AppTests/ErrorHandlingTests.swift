//
//  ErrorHandlingTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

@MainActor
final class ErrorHandlingTests: XCTestCase {
    func testHandleErrorSetsAlert() {
        let handler = ErrorHandling()
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Something failed"])

        handler.handle(error: error, title: "Error")

        XCTAssertEqual(handler.currentAlert?.title, "Error")
        XCTAssertEqual(handler.currentAlert?.message, "Something failed")
    }

    func testHandleCustomMessageSetsAlertAndDismissAction() {
        let handler = ErrorHandling()
        var dismissed = false

        handler.handle(title: "Saved", message: "All good") {
            dismissed = true
        }

        XCTAssertEqual(handler.currentAlert?.title, "Saved")
        XCTAssertEqual(handler.currentAlert?.message, "All good")
        handler.currentAlert?.dismissAction?()
        XCTAssertTrue(dismissed)
    }
}
