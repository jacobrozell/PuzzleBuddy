//
//  Puzzle_BuddyUITestsLaunchTests.swift
//  Puzzle BuddyUITests
//
//  Created by Jacob Rozell on 7/12/22.
//

import XCTest

class Puzzle_BuddyUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to puzzle list with seeded demo data for screenshot capture.

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
