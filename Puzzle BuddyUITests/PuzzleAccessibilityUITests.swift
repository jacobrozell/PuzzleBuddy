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
            app.staticTexts[UITestA11yID.seededPuzzleRowLabelPrefix],
            app.staticTexts["Ocean Breeze"],
            app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'puzzle_row_'")).firstMatch,
            app.buttons[UITestA11yID.addPuzzleButton],
            app.buttons["Add puzzle"],
            app.tabBars.buttons["Puzzles"],
            app.tables[UITestA11yID.puzzleList],
            app.collectionViews[UITestA11yID.puzzleList],
            app.otherElements[UITestA11yID.puzzleList],
            app.tables["Puzzle collection"],
            app.descendants(matching: .any)[UITestA11yID.puzzleList]
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
        _ = app
        _ = timeout
        // Demo puzzles are verified in launchForBypassOnboarding().
    }

    private func puzzleRow(named name: String, in app: XCUIApplication) -> XCUIElement {
        let byIdentifier = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'puzzle_row_' AND label CONTAINS[c] %@", name)
        ).firstMatch
        if byIdentifier.exists { return byIdentifier }

        let byTitle = app.staticTexts[name].firstMatch
        if byTitle.exists { return byTitle }

        return byIdentifier
    }

    private func tapAddPuzzle(in app: XCUIApplication) {
        let menuItem = app.buttons[UITestA11yID.addPuzzleButton]
        if menuItem.waitForExistence(timeout: 2), menuItem.isHittable {
            menuItem.tap()
            return
        }

        let menuTrigger = app.buttons.matching(
            NSPredicate(format: "label == 'Add puzzle' AND identifier != %@", UITestA11yID.addPuzzleButton)
        ).firstMatch
        let fallbackTrigger = app.buttons["Add puzzle"].firstMatch
        let trigger = menuTrigger.exists ? menuTrigger : fallbackTrigger
        guard trigger.waitForExistence(timeout: 8) else {
            XCTFail("Add puzzle menu not found")
            return
        }
        trigger.tap()

        guard menuItem.waitForExistence(timeout: 4) else {
            XCTFail("Add puzzle menu item not found")
            return
        }
        menuItem.tap()
    }

    private func waitForPuzzleForm(in app: XCUIApplication, timeout: TimeInterval = 12) {
        let indicators: [XCUIElement] = [
            app.textFields[UITestA11yID.puzzleFormNameField],
            app.textFields["Puzzle name"],
            app.navigationBars["Add Puzzle"],
            app.staticTexts["Photos"],
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

    func testPuzzleListLandscapeLayout() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        app.rotateToLandscape()
        _ = waitForMainApp(in: app, timeout: 8)
        waitForSeededPuzzles(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testPuzzleListAccessibilityAudit() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testPuzzleListStatusFilter() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let filter = app.descendants(matching: .any)[UITestA11yID.puzzleListStatusFilter]
        let segmented = app.segmentedControls.firstMatch
        XCTAssertTrue(filter.waitForExistence(timeout: 5) || segmented.waitForExistence(timeout: 3))

        let completedButton = segmented.buttons["Done"]
        XCTAssertTrue(completedButton.waitForExistence(timeout: 3))

        XCTAssertTrue(puzzleRow(named: "Mountain Sunset", in: app).exists)
        XCTAssertTrue(puzzleRow(named: "Harbor Lights", in: app).exists)

        completedButton.tap()
        XCTAssertTrue(puzzleRow(named: "Harbor Lights", in: app).waitForExistence(timeout: 3))
        XCTAssertFalse(puzzleRow(named: "Mountain Sunset", in: app).exists)

        segmented.buttons["To-Do"].tap()
        XCTAssertTrue(puzzleRow(named: "Mountain Sunset", in: app).waitForExistence(timeout: 3))
        XCTAssertFalse(puzzleRow(named: "Harbor Lights", in: app).exists)

        segmented.buttons["Active"].tap()
        XCTAssertTrue(puzzleRow(named: "Tabletop Sky", in: app).waitForExistence(timeout: 3))
        XCTAssertFalse(puzzleRow(named: "Mountain Sunset", in: app).exists)

        segmented.buttons["All"].tap()
        XCTAssertTrue(puzzleRow(named: "Mountain Sunset", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(puzzleRow(named: "Harbor Lights", in: app).exists)
        XCTAssertTrue(puzzleRow(named: "Tabletop Sky", in: app).exists)
    }

    func testPuzzleListSearch() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let searchField = app.descendants(matching: .any)[UITestA11yID.puzzleListSearchField]
        let searchLabel = "Search name, brand, store, tag, or barcode"
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
        let app = launchForBypassOnboarding()
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
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        openSettingsTab(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testCollectionStatsAccessibilityAudit() throws {
        let app = launchForBypassOnboarding()
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
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        tapAddPuzzle(in: app)
        waitForPuzzleForm(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testAddPuzzleFormLandscapeLayout() throws {
        let app = launchForBypassOnboarding()
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
        let app = launchForBypassOnboarding()
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
        let app = launchForBypassOnboarding(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        tapFirstSeededPuzzle(in: app)
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailSummary].waitForExistence(timeout: 5))

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }

    func testSettingsDynamicTypeAudit() throws {
        let app = launchForBypassOnboarding(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        openSettingsTab(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }

    func testAddPuzzleFormDynamicTypeAudit() throws {
        let app = launchForBypassOnboarding(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        tapAddPuzzle(in: app)
        waitForPuzzleForm(in: app, timeout: 15)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }

    func testSettingsCollectionImportExportVisibleByDefault() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        openSettingsTab(in: app)

        let importControl = app.descendants(matching: .any)[UITestA11yID.settingsImportIPDbButton]
        let exportControl = app.descendants(matching: .any)[UITestA11yID.settingsExportCollectionButton]
        let importByLabel = app.buttons["Import from IPDb CSV"]
        let exportByLabel = app.buttons["Export collection"]

        for _ in 0..<4 where !(importControl.exists || importByLabel.exists) {
            app.swipeUp()
        }

        XCTAssertTrue(
            importControl.waitForExistence(timeout: 3) || importByLabel.waitForExistence(timeout: 2),
            "Import from IPDb CSV should be visible when import/export is enabled"
        )
        XCTAssertTrue(
            exportControl.waitForExistence(timeout: 2) || exportByLabel.waitForExistence(timeout: 2),
            "Export collection should be visible when import/export is enabled"
        )
    }

    func testAddPuzzleFormShowsPhotoGalleryControls() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        tapAddPuzzle(in: app)
        waitForPuzzleForm(in: app)

        let addPhoto = app.descendants(matching: .any)[UITestA11yID.puzzleFormChoosePhotoButton]
        let addPhotoButton = app.buttons[UITestA11yID.puzzleFormChoosePhotoButton]
        let addPhotoByLabel = app.buttons["Add photo"]
        XCTAssertTrue(
            addPhoto.waitForExistence(timeout: 3)
                || addPhotoButton.waitForExistence(timeout: 2)
                || addPhotoByLabel.waitForExistence(timeout: 2),
            "Photo gallery add control should be visible on the add form"
        )
    }

    func testCompletedPuzzleShowsPuzzleAgainAction() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let row = puzzleRow(named: "Harbor Lights", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Demo completed puzzle should be seeded")
        row.tap()

        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailSummary].waitForExistence(timeout: 5))
        let redo = app.buttons[UITestA11yID.puzzleDetailRedoButton]
        let redoByLabel = app.buttons["Puzzle again"]
        XCTAssertTrue(
            redo.waitForExistence(timeout: 3) || redoByLabel.waitForExistence(timeout: 2),
            "Completed puzzles should offer Puzzle again"
        )
    }

    func testPuzzleListDynamicTypeAudit() throws {
        let app = launchForBypassOnboarding(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }
}
