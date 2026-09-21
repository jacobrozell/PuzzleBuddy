//
//  PuzzleBuddyTests.swift
//  Puzzle BuddyTests
//

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
}
