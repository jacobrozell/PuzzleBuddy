//
//  PuzzleAccessibilityUITests.swift
//  Puzzle BuddyUITests
//

import XCTest

final class PuzzleAccessibilityUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func waitForMainApp(
        in app: XCUIApplication,
        timeout: TimeInterval = 15,
        expectsSeededPuzzles: Bool = false
    ) -> XCUIElement {
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
                if expectsSeededPuzzles {
                    let seededRow = app.buttons.matching(
                        NSPredicate(format: "label BEGINSWITH %@", UITestA11yID.seededPuzzleRowLabelPrefix)
                    ).firstMatch
                    if seededRow.waitForExistence(timeout: 2) {
                        return seededRow
                    }
                } else {
                    return element
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        XCTFail("Main puzzle screen not found")
        return app.buttons[UITestA11yID.addPuzzleButton]
    }

    private func tapAddPuzzle(in app: XCUIApplication) {
        let addByID = app.buttons[UITestA11yID.addPuzzleButton]
        let addByLabel = app.buttons["Add puzzle"]
        guard addByID.waitForExistence(timeout: 8) || addByLabel.waitForExistence(timeout: 3) else {
            XCTFail("Add puzzle button not found")
            return
        }

        let button = addByID.exists ? addByID : addByLabel
        if button.isHittable {
            button.tap()
        } else {
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func waitForPuzzleForm(in app: XCUIApplication, timeout: TimeInterval = 12) {
        let indicators: [XCUIElement] = [
            app.textFields[UITestA11yID.puzzleFormNameField],
            app.textFields["Puzzle name"],
            app.navigationBars["Add Puzzle"],
            app.buttons[UITestA11yID.puzzleFormSubmitButton],
            app.descendants(matching: .any)[UITestA11yID.puzzleFormRatingControl]
        ]

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for element in indicators where element.exists {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        XCTFail("Puzzle form not found")
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
        try LoginUITestGate.skipForLocalFirstRelease()
    }

    func testLoginScreenDynamicTypeAudit() throws {
        try LoginUITestGate.skipForLocalFirstRelease()
    }

    func testLoginScreenLandscapeLayout() throws {
        try LoginUITestGate.skipForLocalFirstRelease()
    }

    func testPuzzleListLandscapeLayout() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        app.rotateToLandscape()
        _ = waitForMainApp(in: app, timeout: 8, expectsSeededPuzzles: true)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testPuzzleListAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testPuzzleListStatusFilter() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        let filter = app.descendants(matching: .any)[UITestA11yID.puzzleListStatusFilter]
        let segmented = app.segmentedControls.firstMatch
        XCTAssertTrue(filter.waitForExistence(timeout: 5) || segmented.waitForExistence(timeout: 3))

        let completedButton = segmented.buttons["Completed"]
        XCTAssertTrue(completedButton.waitForExistence(timeout: 3))

        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Mountain Sunset")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Harbor Lights")).firstMatch.exists)

        completedButton.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Harbor Lights")).firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Mountain Sunset")).firstMatch.exists)

        segmented.buttons["To-Do"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Mountain Sunset")).firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Harbor Lights")).firstMatch.exists)

        segmented.buttons["In-Progress"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Tabletop Sky")).firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Mountain Sunset")).firstMatch.exists)

        segmented.buttons["All"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Mountain Sunset")).firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Harbor Lights")).firstMatch.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Tabletop Sky")).firstMatch.exists)
    }

    func testPuzzleListSearch() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        let searchField = app.descendants(matching: .any)[UITestA11yID.puzzleListSearchField]
        if !searchField.waitForExistence(timeout: 3) {
            XCTAssertTrue(app.textFields["Search by name"].waitForExistence(timeout: 5))
        }
        let field = searchField.exists ? searchField : app.textFields["Search by name"]
        field.tap()
        field.typeText("mountain")

        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Mountain Sunset")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Ocean Breeze")).firstMatch.exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Harbor Lights")).firstMatch.exists)
    }

    func testPuzzleListShowsRatingsOnRows() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        let fourStarRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Mountain Sunset", "Rating 4.0")
        ).firstMatch
        XCTAssertTrue(fourStarRow.waitForExistence(timeout: 5))

        let fiveStarRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Ocean Breeze", "Rating 5.0")
        ).firstMatch
        XCTAssertTrue(fiveStarRow.exists)
    }

    func testSettingsAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Help & Legal"].waitForExistence(timeout: 3))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testCollectionStatsAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        let statsTab = app.tabBars.buttons["Stats"]
        XCTAssertTrue(statsTab.waitForExistence(timeout: 5))
        statsTab.tap()

        XCTAssertTrue(app.staticTexts["Your collection at a glance"].waitForExistence(timeout: 5))

        let completedCard = app.descendants(matching: .any)[UITestA11yID.collectionStatsCompletedCard]
        let completedByLabel = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Puzzles completed")
        ).firstMatch
        XCTAssertTrue(
            completedCard.waitForExistence(timeout: 2) || completedByLabel.waitForExistence(timeout: 3)
        )

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testAddPuzzleFormAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        tapAddPuzzle(in: app)
        waitForPuzzleForm(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testAddPuzzleFormLandscapeLayout() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        tapAddPuzzle(in: app)
        waitForPuzzleForm(in: app)

        app.rotateToLandscape()
        waitForPuzzleForm(in: app, timeout: 8)

        let nameField = app.textFields[UITestA11yID.puzzleFormNameField]
        let nameByLabel = app.textFields["Puzzle name"]
        XCTAssertTrue(nameField.exists || nameByLabel.exists)

        let submitButton = app.buttons[UITestA11yID.puzzleFormSubmitButton]
        let submitByLabel = app.buttons["Save"]
        XCTAssertTrue(submitButton.exists || submitByLabel.exists)
    }

    func testPuzzleDetailAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        tapFirstSeededPuzzle(in: app)
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailSummary].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailStats].exists)
        XCTAssertTrue(app.buttons[UITestA11yID.puzzleDetailEditButton].exists)
        XCTAssertFalse(app.staticTexts["Pieces per minute"].exists)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testPuzzleDetailDynamicTypeAudit() throws {
        let app = launchForBypassAuth(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        tapFirstSeededPuzzle(in: app)
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailSummary].waitForExistence(timeout: 5))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }

    func testSettingsDynamicTypeAudit() throws {
        let app = launchForBypassAuth(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Help & Legal"].waitForExistence(timeout: 3))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }

    func testAddPuzzleFormDynamicTypeAudit() throws {
        let app = launchForBypassAuth(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        tapAddPuzzle(in: app)
        waitForPuzzleForm(in: app, timeout: 15)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }

    func testPuzzleListDynamicTypeAudit() throws {
        let app = launchForBypassAuth(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app, expectsSeededPuzzles: true)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }
}
