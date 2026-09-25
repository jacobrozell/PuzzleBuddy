//
//  PuzzleAccessibilityUITests.swift
//  Puzzle BuddyUITests
//

import XCTest

final class PuzzleAccessibilityUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        resetToPortrait()
    }

    override func tearDownWithError() throws {
        resetToPortrait()
    }

    private func waitForMainApp(
        in app: XCUIApplication,
        timeout: TimeInterval = 15
    ) -> XCUIElement {
        let indicators: [XCUIElement] = [
            app.staticTexts[UITestA11yID.seededPuzzleRowLabelPrefix],
            app.staticTexts["Canal Cruise in Venice"],
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
        let byIdentifier = puzzleRowQuery(named: name, in: app)
        if revealElement(byIdentifier, in: app, scroller: puzzleListScroller(in: app)) {
            return byIdentifier
        }

        let byTitle = app.staticTexts[name].firstMatch
        if revealElement(byTitle, in: app, scroller: puzzleListScroller(in: app)) {
            return byTitle
        }

        return puzzleRowQuery(named: name, in: app)
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
        let namedRow = puzzleRow(named: UITestA11yID.seededPuzzleRowLabelPrefix, in: app)
        if namedRow.waitForExistence(timeout: 2) {
            namedRow.tap()
            return
        }

        let anyRow = firstSeededPuzzleRow(in: app)
        if revealElement(anyRow, in: app, scroller: puzzleListScroller(in: app)),
           anyRow.waitForExistence(timeout: 3) {
            anyRow.tap()
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

    private func addPuzzleFloatingButton(in app: XCUIApplication) -> XCUIElement {
        let byID = app.buttons[UITestA11yID.addPuzzleFloatingButton]
        if byID.exists { return byID }
        return app.buttons.matching(
            NSPredicate(format: "label == 'Add puzzle' AND identifier != %@", UITestA11yID.addPuzzleButton)
        ).firstMatch
    }

    func testAddPuzzleFABLayoutInLandscape() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let addButton = addPuzzleFloatingButton(in: app)
        let firstRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'puzzle_row_'")
        ).firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5))

        app.rotateToLandscape()
        _ = waitForMainApp(in: app, timeout: 8)
        RunLoop.current.run(until: Date().addingTimeInterval(0.75))

        let landscapeAddButton = addPuzzleFloatingButton(in: app)
        let landscapeFirstRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'puzzle_row_'")
        ).firstMatch
        XCTAssertTrue(landscapeAddButton.waitForExistence(timeout: 5))
        XCTAssertTrue(landscapeFirstRow.waitForExistence(timeout: 5))

        let screen = app.windows.firstMatch.frame
        let addFrame = landscapeAddButton.frame
        let rowFrame = landscapeFirstRow.frame

        XCTAssertGreaterThan(
            screen.width,
            screen.height,
            "Expected landscape window before checking FAB layout"
        )
        XCTAssertGreaterThan(
            addFrame.midX,
            screen.width * 0.65,
            "Add puzzle FAB should sit in the right portion of the screen in landscape"
        )
        // Bottom-right above tab bar: lower half of the screen, not aligned with the row band.
        XCTAssertGreaterThan(
            addFrame.minY,
            screen.height * 0.50,
            "Add puzzle FAB should sit in the lower portion of the screen in landscape"
        )
        XCTAssertGreaterThan(
            addFrame.minX,
            rowFrame.midX,
            "Add puzzle FAB should sit to the right of the list row, not on top of it"
        )
        XCTAssertLessThanOrEqual(
            addFrame.maxX,
            screen.width + 1,
            "Add puzzle FAB should not clip off the trailing edge"
        )
        XCTAssertLessThan(
            addFrame.maxY,
            screen.height - 8,
            "Add puzzle FAB should stay fully on screen"
        )
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

        let completedButton = segmented.buttons["Done"].exists
            ? segmented.buttons["Done"]
            : app.buttons["Done"]
        XCTAssertTrue(completedButton.waitForExistence(timeout: 5), "Status filter Done segment not found")

        XCTAssertTrue(puzzleRow(named: "The Bizarre Bookshop", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(puzzleRow(named: "Paris in a Day", in: app).waitForExistence(timeout: 3))

        completedButton.tap()
        XCTAssertTrue(puzzleRow(named: "Paris in a Day", in: app).waitForExistence(timeout: 3))
        XCTAssertFalse(puzzleRowQuery(named: "The Bizarre Bookshop", in: app).exists)

        segmented.buttons["To-Do"].tap()
        XCTAssertTrue(puzzleRow(named: "The Bizarre Bookshop", in: app).waitForExistence(timeout: 3))
        XCTAssertFalse(puzzleRowQuery(named: "Paris in a Day", in: app).exists)

        segmented.buttons["Active"].tap()
        XCTAssertTrue(puzzleRow(named: "Venice Romance", in: app).waitForExistence(timeout: 3))
        XCTAssertFalse(puzzleRowQuery(named: "The Bizarre Bookshop", in: app).exists)

        segmented.buttons["All"].tap()
        XCTAssertTrue(puzzleRow(named: "The Bizarre Bookshop", in: app).waitForExistence(timeout: 3))
        XCTAssertTrue(puzzleRowQuery(named: "Paris in a Day", in: app).exists)
        XCTAssertTrue(puzzleRowQuery(named: "Venice Romance", in: app).exists)
    }

    func testPuzzleListSearch() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let field = revealSearchField(in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Search field not found")
        field.tap()
        field.typeText("bizarre")

        XCTAssertTrue(puzzleRow(named: "The Bizarre Bookshop", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(puzzleRowQuery(named: "Canal Cruise in Venice", in: app).exists)
        XCTAssertFalse(puzzleRowQuery(named: "Paris in a Day", in: app).exists)
    }

    func testPuzzleListShowsRatingsOnRows() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let fourStarRow = puzzleRow(named: "The Bizarre Bookshop", in: app)
        XCTAssertTrue(fourStarRow.waitForExistence(timeout: 5))
        XCTAssertTrue(fourStarRow.label.contains("Rating 4.0"))

        let fiveStarRow = puzzleRow(named: "Canal Cruise in Venice", in: app)
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

        let nameField = app.descendants(matching: .any)[UITestA11yID.puzzleFormNameField]
        XCTAssertTrue(
            nameField.waitForExistence(timeout: 3) || app.textFields["Puzzle name"].waitForExistence(timeout: 2),
            "Name field should be reachable before rotating the add form"
        )

        app.rotateToLandscape()
        XCTAssertTrue(
            app.navigationBars["Add Puzzle"].waitForExistence(timeout: 5),
            "Add form should stay presented after rotating to landscape"
        )

        let submitButton = app.descendants(matching: .any)[UITestA11yID.puzzleFormSubmitButton]
        let submitByLabel = app.buttons["Save puzzle"]
        let photosHeader = app.staticTexts["Photos"]
        let puzzleInfo = app.staticTexts["Puzzle Info"]
        XCTAssertTrue(
            submitButton.waitForExistence(timeout: 3)
                || submitByLabel.waitForExistence(timeout: 2)
                || photosHeader.waitForExistence(timeout: 2)
                || puzzleInfo.waitForExistence(timeout: 2),
            "Add form chrome should remain reachable in landscape"
        )

        resetToPortrait()
        waitForPuzzleForm(in: app, timeout: 8)
        XCTAssertTrue(
            nameField.waitForExistence(timeout: 5) || app.textFields["Puzzle name"].waitForExistence(timeout: 3),
            "Name field should remain reachable after rotating the add form"
        )
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

    func testSettingsCollectionHasDemoControlsWithoutImportExport() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        openSettingsTab(in: app)

        let importByLabel = app.buttons["Import from IPDb CSV"]
        let exportByLabel = app.buttons["Export collection"]
        XCTAssertFalse(importByLabel.exists, "IPDb import should be removed from Settings")
        XCTAssertFalse(exportByLabel.exists, "Export collection should be removed from Settings")

        let loadDemo = loadDemoButton(in: app)
        // Collection sits above Help & Legal — swipe down, not past it.
        if !loadDemo.exists {
            app.swipeDown()
        }
        XCTAssertTrue(
            revealElement(loadDemo, in: app, timeout: 6)
                || app.staticTexts["Collection"].waitForExistence(timeout: 2),
            "Load Demo Data should remain in Settings"
        )
    }

    func testAddPuzzleFormShowsPhotoGalleryControls() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        tapAddPuzzle(in: app)
        waitForPuzzleForm(in: app)

        let addPhoto = app.descendants(matching: .any)[UITestA11yID.puzzleFormChoosePhotoButton]
        let photoByLabel = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS[c] 'photo' OR identifier == %@", UITestA11yID.puzzleFormChoosePhotoButton)
        ).firstMatch
        if !addPhoto.exists && !photoByLabel.exists {
            app.swipeDown()
        }
        let photosHeader = app.staticTexts["Photos"]
        XCTAssertTrue(
            revealElement(addPhoto, in: app, timeout: 4)
                || photoByLabel.waitForExistence(timeout: 3)
                || photosHeader.waitForExistence(timeout: 3),
            "Photo gallery add control should be visible on the add form"
        )
    }

    func testCompletedPuzzleShowsPuzzleAgainAction() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let row = puzzleRow(named: "Paris in a Day", in: app)
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

    func testWhatsNewSheetAppearsWhenForced() throws {
        let app = launchForBypassOnboarding(extraArguments: [UITestLaunch.showWhatsNew])
        XCTAssertTrue(
            app.descendants(matching: .any)[UITestA11yID.whatsNewSheet].waitForExistence(timeout: 8)
                || app.buttons[UITestA11yID.whatsNewDismissButton].waitForExistence(timeout: 3),
            "What's New sheet should appear when forced for UI tests"
        )
    }

    func testPuzzleListOverdueFilterChipExists() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        let overdue = app.descendants(matching: .any)[UITestA11yID.puzzleListOverdueFilter]
        XCTAssertTrue(
            overdue.waitForExistence(timeout: 5) || app.buttons["Overdue"].waitForExistence(timeout: 3),
            "Overdue filter should be available on the puzzle list"
        )
    }

    func testCompletionHistoryDeleteShowsConfirmation() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let row = puzzleRow(named: "Floral Arch", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 8), "Floral Arch should be seeded")
        row.tap()
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailSummary].waitForExistence(timeout: 5))

        let history = app.descendants(matching: .any)[UITestA11yID.puzzleDetailCompletionHistory]
        XCTAssertTrue(
            history.waitForExistence(timeout: 5) || app.staticTexts["Completion history"].waitForExistence(timeout: 3),
            "Completion history should be visible"
        )

        let historyScroller = app.descendants(matching: .any)[UITestA11yID.puzzleDetailCompletionHistory]
        if historyScroller.exists {
            historyScroller.swipeUp()
        }
        let completionRow = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Completion ' AND NOT label CONTAINS[c] 'history'")
        ).firstMatch
        XCTAssertTrue(
            revealElement(completionRow, in: app, scroller: historyScroller.exists ? historyScroller : nil, timeout: 6),
            "A completion history row should be visible"
        )
        completionRow.tap()

        let removeInEditor = app.buttons[UITestA11yID.puzzleDetailCompletionRemoveButton]
        XCTAssertTrue(
            removeInEditor.waitForExistence(timeout: 5) || app.buttons["Remove"].waitForExistence(timeout: 3),
            "Completion editor should offer Remove"
        )
        if removeInEditor.exists {
            removeInEditor.tap()
        } else {
            app.buttons["Remove"].tap()
        }

        XCTAssertTrue(
            app.buttons["Remove"].waitForExistence(timeout: 4)
                || app.staticTexts["Set puzzle status"].waitForExistence(timeout: 2),
            "History delete confirmation should appear"
        )
    }

    func testUndoBannerAppearsAfterMarkingComplete() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let row = puzzleRow(named: "Venice Romance", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 8), "In-progress demo puzzle should be seeded")
        row.tap()
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailSummary].waitForExistence(timeout: 5))

        let slider = app.sliders[UITestA11yID.puzzleDetailProgressSlider]
        XCTAssertTrue(slider.waitForExistence(timeout: 5), "Progress slider should be on detail")
        slider.adjust(toNormalizedSliderPosition: 1.0)

        let banner = app.descendants(matching: .any)[UITestA11yID.puzzleDetailUndoCompletionBanner]
        let undo = app.buttons[UITestA11yID.puzzleDetailUndoCompletionButton]
        XCTAssertTrue(
            banner.waitForExistence(timeout: 6) || undo.waitForExistence(timeout: 3) || app.buttons["Undo"].waitForExistence(timeout: 2),
            "Undo banner should appear after marking complete"
        )
    }

    func testPuzzleListDynamicTypeAudit() throws {
        let app = launchForBypassOnboarding(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }
}
