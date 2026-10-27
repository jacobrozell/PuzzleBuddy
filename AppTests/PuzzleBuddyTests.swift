//
//  PuzzleBuddyTests.swift
//  Puzzle BuddyTests
//

import UIKit
import XCTest
@testable import PuzzleBuddy

final class PuzzleBuddyTests: XCTestCase {
    func testAppVersionIsNonEmpty() {
        XCTAssertFalse(PuzzleBuddyApp.version.isEmpty)
        XCTAssertEqual(
            PuzzleBuddyApp.version,
            Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            "PuzzleBuddyApp.version must stay in sync with MARKETING_VERSION / Info.plist"
        )
    }

    func testAnalyticsAllowlistIncludesBootstrap() {
        let mapped = PuzzleAnalyticsEventMapping.map(
            eventName: "app_bootstrap_ready",
            category: .app,
            metadata: [:],
            appVersion: "test"
        )
        XCTAssertEqual(mapped?.name, "app_open")
        XCTAssertEqual(mapped?.parameters["app_version"] as? String, "test")
    }

    func testAnalyticsAllowlistRejectsUnknownEvents() {
        let mapped = PuzzleAnalyticsEventMapping.map(
            eventName: "secret_user_data",
            category: .app,
            metadata: ["email": "test@example.com"],
            appVersion: "test"
        )
        XCTAssertNil(mapped)
    }

    func testPickNextEnabledForOnePointZero() {
        XCTAssertTrue(ProductService.isPickNextEnabled)
    }

    func testAppInfoDisplayName() {
        XCTAssertEqual(AppInfo.displayName, "Puzzle Buddy")
    }

    func testOnboardingUsesAppDisplayName() {
        XCTAssertFalse(AppInfo.displayName.isEmpty)
        XCTAssertFalse(AppInfo.displayName.localizedCaseInsensitiveContains("Pal"))
    }

    func testBrandBackgroundUIColorMatchesLightAndDarkPalette() {
        let light = Brand.backgroundUIColor.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .light)
        )
        let dark = Brand.backgroundUIColor.resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .dark)
        )

        var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
        var dr: CGFloat = 0, dg: CGFloat = 0, db: CGFloat = 0, da: CGFloat = 0
        XCTAssertTrue(light.getRed(&lr, green: &lg, blue: &lb, alpha: &la))
        XCTAssertTrue(dark.getRed(&dr, green: &dg, blue: &db, alpha: &da))
        XCTAssertEqual(lr, 0.95, accuracy: 0.01)
        XCTAssertEqual(lg, 0.97, accuracy: 0.01)
        XCTAssertEqual(lb, 0.98, accuracy: 0.01)
        XCTAssertEqual(dr, 0.04, accuracy: 0.01)
        XCTAssertEqual(dg, 0.05, accuracy: 0.01)
        XCTAssertEqual(db, 0.07, accuracy: 0.01)
    }

    func testLiquidGlassNavPolicyMatchesRuntime() {
        if #available(iOS 26, *) {
            XCTAssertTrue(SystemNavigationPolicy.usesSystemLiquidGlassNav)
        } else {
            XCTAssertFalse(SystemNavigationPolicy.usesSystemLiquidGlassNav)
        }
    }
}
