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
        timeout: TimeInterval = 15
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
                return element
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        XCTFail("Main puzzle screen not found")
        return app.buttons[UITestA11yID.addPuzzleButton]
    }

    private func waitForSeededPuzzles(in app: XCUIApplication, timeout: TimeInterval = 30) {
        XCTAssertTrue(puzzleRow(named: UITestA11yID.seededPuzzleRowLabelPrefix, in: app).waitForExistence(timeout: timeout))
    }

    private func puzzleRow(named name: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'puzzle_row_' AND label BEGINSWITH %@", name)
        ).firstMatch
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
        let rowButton = puzzleRow(named: UITestA11yID.seededPuzzleRowLabelPrefix, in: app)
        if rowButton.waitForExistence(timeout: 5) {
            rowButton.tap()
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
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        app.rotateToLandscape()
        _ = waitForMainApp(in: app, timeout: 8)
        waitForSeededPuzzles(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testPuzzleListAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testPuzzleListStatusFilter() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let filter = app.descendants(matching: .any)[UITestA11yID.puzzleListStatusFilter]
        let segmented = app.segmentedControls.firstMatch
        XCTAssertTrue(filter.waitForExistence(timeout: 5) || segmented.waitForExistence(timeout: 3))

        let completedButton = segmented.buttons["Completed"]
        XCTAssertTrue(completedButton.waitForExistence(timeout: 3))

        XCTAssertTrue(puzzleRow(named: "Mountain Sunset", in: app).exists)
        XCTAssertTrue(puzzleRow(named: "Harbor Lights", in: app).exists)

        completedButton.tap()
        XCTAssertTrue(puzzleRow(named: "Harbor Lights", in: app).waitForExistence(timeout: 3))
        XCTAssertFalse(puzzleRow(named: "Mountain Sunset", in: app).exists)

        segmented.buttons["To-Do"].tap()
        XCTAssertTrue(puzzleRow(named: "Mountain Sunset", in: app).waitForExistence(timeout: 3))
        XCTAssertFalse(puzzleRow(named: "Harbor Lights", in: app).exists)

        segmented.buttons["In-Progress"].tap()
        XCTAssertTrue(puzzleRow(named: "Tabletop Sky", in: app).waitForExistence(timeout: 3))
        XCTAssertFalse(puzzleRow(named: "Mountain Sunset", in: app).exists)

        segmented.buttons["All"].tap()
        XCTAssertTrue(puzzleRow(named: "Mountain Sunset", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(puzzleRow(named: "Harbor Lights", in: app).exists)
        XCTAssertTrue(puzzleRow(named: "Tabletop Sky", in: app).exists)
    }

    func testPuzzleListSearch() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let searchField = app.descendants(matching: .any)[UITestA11yID.puzzleListSearchField]
        let searchLabel = "Search name, brand, or barcode"
        if !searchField.waitForExistence(timeout: 3) {
            XCTAssertTrue(app.textFields[searchLabel].waitForExistence(timeout: 5))
        }
        let field = searchField.exists ? searchField : app.textFields[searchLabel]
        field.tap()
        field.typeText("mountain")

        XCTAssertTrue(puzzleRow(named: "Mountain Sunset", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(puzzleRow(named: "Ocean Breeze", in: app).exists)
        XCTAssertFalse(puzzleRow(named: "Harbor Lights", in: app).exists)
    }

    func testPuzzleListShowsRatingsOnRows() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let fourStarRow = puzzleRow(named: "Mountain Sunset", in: app)
        XCTAssertTrue(fourStarRow.waitForExistence(timeout: 5))
        XCTAssertTrue(fourStarRow.label.contains("Rating 4.0"))

        let fiveStarRow = puzzleRow(named: "Ocean Breeze", in: app)
        XCTAssertTrue(fiveStarRow.exists)
        XCTAssertTrue(fiveStarRow.label.contains("Rating 5.0"))
    }

    func testSettingsAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Help & Legal"].waitForExistence(timeout: 3))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testCollectionStatsAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

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
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        tapAddPuzzle(in: app)
        waitForPuzzleForm(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testAddPuzzleFormLandscapeLayout() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        tapAddPuzzle(in: app)
        waitForPuzzleForm(in: app)

        app.rotateToLandscape()
        waitForPuzzleForm(in: app, timeout: 8)

        let nameField = app.descendants(matching: .any)[UITestA11yID.puzzleFormNameField]
        let nameByLabel = app.descendants(matching: .any)["Puzzle name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3) || nameByLabel.waitForExistence(timeout: 3))

        let submitButton = app.descendants(matching: .any)[UITestA11yID.puzzleFormSubmitButton]
        let submitByLabel = app.buttons["Save puzzle"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 3) || submitByLabel.waitForExistence(timeout: 3))
    }

    func testPuzzleDetailAccessibilityAudit() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        tapFirstSeededPuzzle(in: app)
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailSummary].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailStats].exists)
        XCTAssertTrue(app.buttons[UITestA11yID.puzzleDetailEditButton].exists)
        XCTAssertFalse(app.staticTexts["Pieces per minute"].exists)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testPuzzleDetailDynamicTypeAudit() throws {
        let app = launchForBypassAuth(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        tapFirstSeededPuzzle(in: app)
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailSummary].waitForExistence(timeout: 5))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }

    func testSettingsDynamicTypeAudit() throws {
        let app = launchForBypassAuth(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Help & Legal"].waitForExistence(timeout: 3))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }

    func testAddPuzzleFormDynamicTypeAudit() throws {
        let app = launchForBypassAuth(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        tapAddPuzzle(in: app)
        waitForPuzzleForm(in: app, timeout: 15)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }

    func testSettingsCollectionDataActionsPresent() throws {
        let app = launchForBypassAuth()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Help & Legal"].waitForExistence(timeout: 3))

        let importButton = app.buttons[UITestA11yID.settingsImportIPDbButton]
        let importByLabel = app.buttons["Import from IPDb CSV"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 3) || importByLabel.waitForExistence(timeout: 3))

        let exportButton = app.buttons[UITestA11yID.settingsExportCollectionButton]
        let exportByLabel = app.buttons["Export collection"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3) || exportByLabel.waitForExistence(timeout: 3))
    }

    func testPuzzleListDynamicTypeAudit() throws {
        let app = launchForBypassAuth(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }
}
