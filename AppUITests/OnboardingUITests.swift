//
//  OnboardingUITests.swift
//  Puzzle BuddyUITests
//

import XCTest

final class OnboardingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingNextBackAndFinish() {
        let app = launchForOnboarding()

        let skip = app.buttons[UITestA11yID.onboardingSkipButton]
        let next = app.buttons[UITestA11yID.onboardingNextButton]
        XCTAssertTrue(skip.waitForExistence(timeout: 8))
        XCTAssertTrue(next.exists)
        XCTAssertFalse(app.buttons[UITestA11yID.onboardingBackButton].exists)

        next.tap()
        let back = app.buttons[UITestA11yID.onboardingBackButton]
        XCTAssertTrue(back.waitForExistence(timeout: 3))

        back.tap()
        XCTAssertTrue(next.waitForExistence(timeout: 3))
        XCTAssertFalse(back.exists)

        // Advance through remaining pages to finish.
        while app.buttons[UITestA11yID.onboardingNextButton].waitForExistence(timeout: 2) {
            app.buttons[UITestA11yID.onboardingNextButton].tap()
        }

        let finish = app.buttons[UITestA11yID.onboardingFinishButton]
        XCTAssertTrue(finish.waitForExistence(timeout: 3), "Expected Get Started on last page")
        finish.tap()

        assertMainAppVisible(in: app)
    }

    func testOnboardingSkipLandsInMainApp() {
        let app = launchForOnboarding()

        let skip = app.buttons[UITestA11yID.onboardingSkipButton]
        XCTAssertTrue(skip.waitForExistence(timeout: 8))
        skip.tap()

        assertMainAppVisible(in: app)
    }

    private func launchForOnboarding() -> XCUIApplication {
        let app = XCUIApplication()
        if app.state == .runningForeground || app.state == .runningBackground {
            app.terminate()
        }
        app.launchArguments = UITestLaunch.onboardingArguments
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        dismissSystemAlertsIfNeeded()
        return app
    }

    private func assertMainAppVisible(in app: XCUIApplication) {
        let addButton = app.descendants(matching: .any)[UITestA11yID.addPuzzleButton]
        let addByLabel = app.buttons["Add puzzle"]
        let puzzlesTab = app.tabBars.buttons["Puzzles"]
        let emptyState = app.descendants(matching: .any)[UITestA11yID.puzzleListEmptyState]

        let deadline = Date().addingTimeInterval(12)
        while Date() < deadline {
            if addButton.exists || addByLabel.exists || puzzlesTab.exists || emptyState.exists {
                break
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }

        XCTAssertTrue(
            addButton.exists || addByLabel.exists || puzzlesTab.exists || emptyState.exists,
            "Main app did not appear after onboarding. \(app.debugDescription.prefix(800))"
        )
        XCTAssertFalse(app.buttons[UITestA11yID.onboardingSkipButton].exists)
    }
}
