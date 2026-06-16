//
//  PuzzleAccessibilityUITests.swift
//  Puzzle BuddyUITests
//

import XCTest

final class PuzzleAccessibilityUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func waitForMainApp(in app: XCUIApplication, timeout: TimeInterval = 15) -> XCUIElement {
        let indicators: [XCUIElement] = [
            app.buttons[UITestA11yID.addPuzzleButton],
            app.buttons["Add puzzle"],
            app.staticTexts["Mountain Sunset"],
            app.staticTexts["Ocean Breeze"],
            app.tabBars.buttons["Puzzles"],
            app.tables[UITestA11yID.puzzleList],
            app.collectionViews[UITestA11yID.puzzleList],
            app.otherElements[UITestA11yID.puzzleList],
            app.tables["Puzzle collection"],
            app.descendants(matching: .any)[UITestA11yID.puzzleList],
            app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'puzzle_row_'")).firstMatch
        ]

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for element in indicators where element.exists {
                return element
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        XCTFail("Main puzzle screen not found")
        return app.buttons[UITestA11yID.addPuzzleButton]
    }

    private func tapAddPuzzle(in app: XCUIApplication) {
        let addByID = app.buttons[UITestA11yID.addPuzzleButton]
        let addByLabel = app.buttons["Add puzzle"]
        if addByID.waitForExistence(timeout: 5) {
            addByID.tap()
        } else if addByLabel.waitForExistence(timeout: 3) {
            addByLabel.tap()
        } else {
            XCTFail("Add puzzle button not found")
        }
    }

    private func tapFirstSeededPuzzle(in app: XCUIApplication) {
        let rowButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", UITestA11yID.seededPuzzleRowLabelPrefix)
        ).firstMatch
        if rowButton.waitForExistence(timeout: 5) {
            rowButton.tap()
            return
        }

        let rowLink = app.staticTexts[UITestA11yID.seededPuzzleRowLabelPrefix]
        if rowLink.waitForExistence(timeout: 3) {
            rowLink.tap()
            return
        }

        XCTFail("Seeded puzzle row not found")
    }

    func testLoginScreenAccessibilityAudit() throws {
        let app = launchForLogin()
        XCTAssertTrue(app.textFields[UITestA11yID.loginEmailField].waitForExistence(timeout: 5))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testLoginScreenDynamicTypeAudit() throws {
        let app = launchForLogin(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        XCTAssertTrue(app.textFields[UITestA11yID.loginEmailField].waitForExistence(timeout: 5))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }

    func testLoginScreenLandscapeLayout() throws {
        let app = launchForLogin()
        XCTAssertTrue(app.textFields[UITestA11yID.loginEmailField].waitForExistence(timeout: 5))

        app.rotateToLandscape()
        XCTAssertTrue(app.textFields[UITestA11yID.loginEmailField].exists)
        XCTAssertTrue(app.buttons[UITestA11yID.loginSubmitButton].exists)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testPuzzleListLandscapeLayout() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)

        app.rotateToLandscape()
        _ = waitForMainApp(in: app, timeout: 8)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testPuzzleListAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testSettingsAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Help & Legal"].waitForExistence(timeout: 3))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testAddPuzzleFormAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)

        tapAddPuzzle(in: app)
        XCTAssertTrue(app.textFields[UITestA11yID.puzzleFormNameField].waitForExistence(timeout: 5))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testAddPuzzleFormLandscapeLayout() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)

        tapAddPuzzle(in: app)
        XCTAssertTrue(app.textFields[UITestA11yID.puzzleFormNameField].waitForExistence(timeout: 5))

        app.rotateToLandscape()
        XCTAssertTrue(app.textFields[UITestA11yID.puzzleFormNameField].exists)
        XCTAssertTrue(app.buttons[UITestA11yID.puzzleFormSubmitButton].exists)
    }

    func testPuzzleDetailAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)

        tapFirstSeededPuzzle(in: app)
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailSummary].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailStats].exists)
        XCTAssertTrue(app.buttons[UITestA11yID.puzzleDetailEditButton].exists)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }
}
