//
//  WCAGAccessibilitySupport.swift
//  Puzzle BuddyUITests
//

import XCTest

enum WCAGAccessibilityAuditProfile {
    static let nameRoleValue: XCUIAccessibilityAuditType = [.elementDetection, .sufficientElementDescription]
    static let touchTargets: XCUIAccessibilityAuditType = .hitRegion
    static let dynamicType: XCUIAccessibilityAuditType = [.dynamicType, .textClipped]
}

extension XCTestCase {
    func launchForLogin(
        extraArguments: [String] = [],
        contentSizeCategory: String? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = UITestLaunch.loginArguments + extraArguments
        if let contentSizeCategory {
            app.launchEnvironment["UIPreferredContentSizeCategoryName"] = contentSizeCategory
        }
        app.launch()
        return app
    }

    func launchForAccessibility(
        extraArguments: [String] = [],
        contentSizeCategory: String? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = UITestLaunch.defaultArguments + extraArguments
        if let contentSizeCategory {
            app.launchEnvironment["UIPreferredContentSizeCategoryName"] = contentSizeCategory
        }
        app.launch()
        return app
    }

    func launchForBypassAuth(
        extraArguments: [String] = [],
        contentSizeCategory: String? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        if app.state == .runningForeground {
            app.terminate()
        }
        app.launchArguments = UITestLaunch.bypassArguments + extraArguments
        app.launchEnvironment = [
            "UI_TESTING_BYPASS_AUTH": "1",
            "UI_TESTING_SEED_PUZZLES": "1"
        ]
        if let contentSizeCategory {
            app.launchEnvironment["UIPreferredContentSizeCategoryName"] = contentSizeCategory
        }
        app.launch()
        dismissSystemAlertsIfNeeded()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
        app.activate()

        let addButton = app.descendants(matching: .any)[UITestA11yID.addPuzzleButton]
        let addByLabel = app.buttons["Add puzzle"]
        let seededRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'puzzle_row_'")
        ).firstMatch

        let deadline = Date().addingTimeInterval(30)
        while Date() < deadline {
            if addButton.exists || addByLabel.exists || seededRow.exists { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }

        XCTAssertTrue(
            addButton.exists || addByLabel.exists || seededRow.exists,
            "Puzzle list did not load. \(app.debugDescription.prefix(1_000))"
        )

        let puzzleRows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'puzzle_row_'")
        ).firstMatch
        XCTAssertTrue(
            puzzleRows.waitForExistence(timeout: 30),
            "Seeded puzzles did not appear."
        )

        return app
    }

    private func dismissSystemAlertsIfNeeded() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deny = springboard.alerts.buttons["Don’t Allow"]
        if deny.waitForExistence(timeout: 2) {
            deny.tap()
        }
        let denyAlt = springboard.alerts.buttons["Don't Allow"]
        if denyAlt.waitForExistence(timeout: 1) {
            denyAlt.tap()
        }
    }

    func runWCAGAudit(
        on app: XCUIApplication,
        auditTypes: XCUIAccessibilityAuditType,
        ignoring issueFilter: ((XCUIAccessibilityAuditIssue) -> Bool)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            try app.performAccessibilityAudit(for: auditTypes) { issue in
                issueFilter?(issue) ?? false
            }
        } catch {
            XCTFail(
                "WCAG accessibility audit failed (\(auditTypes)): \(error.localizedDescription)",
                file: file,
                line: line
            )
        }
    }
}

extension XCUIApplication {
    func rotateToLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        _ = wait(for: .runningForeground, timeout: 3)
    }
}
