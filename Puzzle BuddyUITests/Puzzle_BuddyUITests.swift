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
        let app = XCUIApplication()
        app.launchArguments += UITestLaunch.loginArguments
        app.launch()

        XCTAssertTrue(app.textFields[UITestA11yID.loginEmailField].waitForExistence(timeout: 5))
        XCTAssertTrue(app.secureTextFields[UITestA11yID.loginPasswordField].exists)
        XCTAssertTrue(app.buttons[UITestA11yID.loginSubmitButton].exists)
    }
}
