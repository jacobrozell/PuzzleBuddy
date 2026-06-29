//
//  Puzzle_BuddyTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class Puzzle_BuddyTests: XCTestCase {
    func testAppVersionIsNonEmpty() {
        XCTAssertFalse(Puzzle_BuddyApp.version.isEmpty)
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

    func testCollectionImportExportEnabledByDefault() {
        XCTAssertTrue(ProductService.isCollectionImportExportEnabled)
    }

    func testAppInfoDisplayName() {
        XCTAssertEqual(AppInfo.displayName, "Puzzle Buddy")
    }

    func testOnboardingUsesAppDisplayName() {
        XCTAssertFalse(AppInfo.displayName.isEmpty)
        XCTAssertFalse(AppInfo.displayName.localizedCaseInsensitiveContains("Pal"))
    }
}
