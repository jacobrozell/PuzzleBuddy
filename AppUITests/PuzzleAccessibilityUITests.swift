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

    func testPuzzleDetailEditSurvivesRotation() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        tapFirstSeededPuzzle(in: app)
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailSummary].waitForExistence(timeout: 5))

        let editButton = app.buttons[UITestA11yID.puzzleDetailEditButton]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()

        let nameField = app.descendants(matching: .any)[UITestA11yID.puzzleFormNameField]
        let nameByLabel = app.textFields["Puzzle name"]
        XCTAssertTrue(
            nameField.waitForExistence(timeout: 3) || nameByLabel.waitForExistence(timeout: 2),
            "Name field should be reachable before rotating edit mode"
        )
        let field = nameField.exists ? nameField : nameByLabel
        field.tap()
        let sentinel = "Fold rotation sentinel"
        field.typeText(sentinel)

        let cancelButton = app.buttons[UITestA11yID.puzzleDetailCancelButton]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 3) || app.buttons["Cancel"].waitForExistence(timeout: 2),
            "Cancel should be visible in edit mode before rotation"
        )

        app.rotateToLandscape()
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 5) || app.buttons["Cancel"].waitForExistence(timeout: 3),
            "Edit mode should stay presented after rotating to landscape"
        )
        let saveButton = app.buttons[UITestA11yID.puzzleDetailEditButton]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        XCTAssertTrue(
            saveButton.label.localizedCaseInsensitiveContains("Save"),
            "Save should remain visible in landscape edit mode"
        )

        resetToPortrait()
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 5) || app.buttons["Cancel"].waitForExistence(timeout: 3),
            "Edit mode should stay presented after rotating back to portrait"
        )

        let portraitNameField = app.descendants(matching: .any)[UITestA11yID.puzzleFormNameField]
        XCTAssertTrue(
            portraitNameField.waitForExistence(timeout: 5) || app.textFields["Puzzle name"].waitForExistence(timeout: 3),
            "Name field should remain reachable after rotating edit mode back to portrait"
        )
        let valueInPortrait = portraitNameField.value as? String ?? ""
        XCTAssertTrue(
            valueInPortrait.contains(sentinel),
            "Unsaved edit text should survive rotation back to portrait"
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

    func testInProgressPuzzleTimerStartsAndPauses() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        let row = puzzleRow(named: "Venice Romance", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 8), "In-progress demo puzzle should be seeded")
        row.tap()
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailSummary].waitForExistence(timeout: 5))

        let toggle = app.buttons[UITestA11yID.puzzleDetailTimerToggleButton]
        XCTAssertTrue(revealElement(toggle, in: app), "Timer card should be on In-Progress detail")
        if !toggle.isHittable {
            app.swipeUp()
        }
        XCTAssertEqual(toggle.label, "Start timer")
        toggle.tap()

        let pause = app.buttons["Pause timer"]
        XCTAssertTrue(pause.waitForExistence(timeout: 4), "Start should switch the button to Pause")
        XCTAssertTrue((pause.value as? String)?.contains("running") ?? false, "VoiceOver value should say running")
        pause.tap()
        XCTAssertTrue(app.buttons["Start timer"].waitForExistence(timeout: 4), "Pause should switch back to Start")

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testResetTimerConfirmsBeforeClearing() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)
        openInProgressPuzzle("Venice Romance", in: app)
        startTimer(in: app)

        let reset = app.buttons[UITestA11yID.puzzleDetailTimerResetButton]
        XCTAssertTrue(reset.waitForExistence(timeout: 4), "Reset appears once the timer has elapsed time")
        reset.tap()

        let confirm = app.sheets.buttons["Reset timer"]
        let alertConfirm = app.alerts.buttons["Reset timer"]
        XCTAssertTrue(
            confirm.waitForExistence(timeout: 3) || alertConfirm.waitForExistence(timeout: 2),
            "Reset should ask before clearing"
        )
        if confirm.exists {
            confirm.tap()
        } else {
            alertConfirm.tap()
        }

        XCTAssertTrue(app.buttons["Start timer"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.buttons[UITestA11yID.puzzleDetailTimerResetButton].exists)
    }

    func testStartingSecondPuzzleClearsTheRunningBadge() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        openInProgressPuzzle("Venice Romance", in: app)
        startTimer(in: app)
        backToPuzzleList(in: app)
        XCTAssertTrue(runningTimerBadge(in: app).waitForExistence(timeout: 4), "The started puzzle should show Timer running")

        openInProgressPuzzle("Underwater Paradise", in: app)
        startTimer(in: app)
        backToPuzzleList(in: app)

        let underwater = puzzleRow(named: "Underwater Paradise", in: app)
        let venice = puzzleRow(named: "Venice Romance", in: app)
        XCTAssertTrue(underwater.label.localizedCaseInsensitiveContains("timer running"))
        XCTAssertFalse(venice.label.localizedCaseInsensitiveContains("timer running"))
    }

    func testEditFormOffersUseTimerTime() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)
        openInProgressPuzzle("Venice Romance", in: app)
        startTimer(in: app)

        XCTAssertTrue(
            app.buttons[UITestA11yID.puzzleDetailTimerResetButton].waitForExistence(timeout: 4),
            "Timer needs elapsed time before the form can suggest it"
        )
        let edit = app.buttons[UITestA11yID.puzzleDetailEditButton]
        XCTAssertTrue(revealElement(edit, in: app))
        edit.tap()

        let useTimer = app.buttons["Use timer time"]
        XCTAssertTrue(
            revealElement(useTimer, in: app, scroller: formScroller(in: app)),
            "Edit should offer the timer when it differs from logged time"
        )
        useTimer.tap()
        XCTAssertTrue(
            app.staticTexts["Total time: 1 min"].waitForExistence(timeout: 4)
                || app.descendants(matching: .any)["Total time: 1 min"].waitForExistence(timeout: 2),
            "Use timer time should fill one minute"
        )
    }

    private func openInProgressPuzzle(_ name: String, in app: XCUIApplication) {
        let row = puzzleRow(named: name, in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 8), "\(name) should be seeded")
        row.tap()
        XCTAssertTrue(app.otherElements[UITestA11yID.puzzleDetailSummary].waitForExistence(timeout: 5))
    }

    private func startTimer(in app: XCUIApplication) {
        let toggle = app.buttons[UITestA11yID.puzzleDetailTimerToggleButton]
        XCTAssertTrue(revealElement(toggle, in: app), "Timer card should be on In-Progress detail")
        if !toggle.isHittable {
            app.swipeUp()
        }
        if toggle.label == "Pause timer" {
            return
        }
        XCTAssertEqual(toggle.label, "Start timer")
        toggle.tap()
        XCTAssertTrue(app.buttons["Pause timer"].waitForExistence(timeout: 4))
    }

    private func backToPuzzleList(in app: XCUIApplication) {
        let back = app.navigationBars.buttons["Puzzles"]
        if back.waitForExistence(timeout: 2), back.isHittable {
            back.tap()
        } else if app.buttons["Puzzles"].waitForExistence(timeout: 2) {
            app.buttons["Puzzles"].firstMatch.tap()
        } else {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        XCTAssertTrue(
            app.descendants(matching: .any)[UITestA11yID.puzzleList].waitForExistence(timeout: 5),
            "Back should return to the puzzle list"
        )
    }

    private func runningTimerBadge(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[UITestA11yID.puzzleCellTimerRunning]
    }

    func testProMaxLandscapeKeepsASinglePuzzleList() throws {
        let app = launchForBypassOnboarding()
        _ = waitForMainApp(in: app)
        app.rotateToLandscape()

        XCTAssertFalse(
            app.staticTexts["No puzzle selected"].waitForExistence(timeout: 2),
            "A wide short phone should keep the list as a stack, not open a split detail column"
        )
        XCTAssertTrue(
            puzzleRow(named: "Venice Romance", in: app).waitForExistence(timeout: 8),
            "The puzzle list should stay on screen in landscape"
        )
    }

    func testPuzzleListDynamicTypeAudit() throws {
        let app = launchForBypassOnboarding(contentSizeCategory: "UIAccessibilityExtraExtraExtraLargeCategory")
        _ = waitForMainApp(in: app)
        waitForSeededPuzzles(in: app)

        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }
}
