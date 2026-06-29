//
//  AppLoggingTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class AppLoggingTests: XCTestCase {
    func testAnalyticsMapsPuzzleEvents() {
        let mapped = PuzzleAnalyticsEventMapping.map(
            eventName: "puzzle_added",
            category: .puzzles,
            metadata: ["puzzle_status": "Completed", "puzzle_count": "3"],
            appVersion: "1.0.0"
        )

        XCTAssertEqual(mapped?.name, "puzzle_added")
        XCTAssertEqual(mapped?.parameters["puzzle_status"] as? String, "Completed")
        XCTAssertEqual(mapped?.parameters["puzzle_count"] as? String, "3")
        XCTAssertEqual(mapped?.parameters["log_category"] as? String, "puzzles")
    }

    func testAnalyticsStripsEmptyMetadataValues() {
        let mapped = PuzzleAnalyticsEventMapping.map(
            eventName: "puzzle_list_refreshed",
            category: .puzzles,
            metadata: ["puzzle_count": "", "puzzle_status": "To-Do"],
            appVersion: "1.0.0"
        )

        XCTAssertNil(mapped?.parameters["puzzle_count"])
        XCTAssertEqual(mapped?.parameters["puzzle_status"] as? String, "To-Do")
    }

    func testLogRedactionRemovesSensitiveKeys() {
        let redacted = LogRedaction.redact([
            "puzzle_count": "2",
            "email": "user@example.com",
            "password": "secret",
            "token": "abc123"
        ])

        XCTAssertEqual(redacted["puzzle_count"], "2")
        XCTAssertNil(redacted["email"])
        XCTAssertNil(redacted["password"])
        XCTAssertNil(redacted["token"])
    }

    func testLogRedactionIsCaseInsensitive() {
        let redacted = LogRedaction.redact(["Email": "user@example.com", "UID": "uid-1"])
        XCTAssertTrue(redacted.isEmpty)
    }

    func testCrashlyticsMapsAllowlistedSyncFailure() {
        let error = FirebaseCrashlyticsEventMapping.nonFatalError(
            level: .error,
            category: .puzzles,
            eventName: "puzzle_load_failed",
            metadata: ["puzzle_status": "To-Do", "email": "secret@example.com"],
            appVersion: "1.0.0"
        )

        XCTAssertEqual(error?.domain, "com.jacobrozell.Puzzle-Buddy.logger")
        XCTAssertEqual(error?.code, 2001)
        XCTAssertEqual(error?.userInfo["event_name"] as? String, "puzzle_load_failed")
        XCTAssertEqual(error?.userInfo["puzzle_status"] as? String, "To-Do")
        XCTAssertNil(error?.userInfo["email"])
    }

    func testCrashlyticsDropsNonAllowlistedErrors() {
        let error = FirebaseCrashlyticsEventMapping.nonFatalError(
            level: .error,
            category: .puzzles,
            eventName: "puzzle_added",
            metadata: [:],
            appVersion: "1.0.0"
        )
        XCTAssertNil(error)
    }

    func testAnalyticsAllowlistsBackupRestore() {
        let restored = PuzzleAnalyticsEventMapping.map(
            eventName: "puzzle_backup_restored",
            category: .puzzles,
            metadata: ["puzzle_count": "3", "import_policy": "merge"],
            appVersion: "1.0.0"
        )
        XCTAssertEqual(restored?.name, "puzzle_backup_restored")
        XCTAssertEqual(restored?.parameters["import_policy"] as? String, "merge")
    }

    func testAnalyticsAllowlistsRedoAndCompletionEvents() {
        let redo = PuzzleAnalyticsEventMapping.map(
            eventName: "puzzle_redo_started",
            category: .puzzles,
            metadata: ["completion_count": "2"],
            appVersion: "1.0.0"
        )
        XCTAssertEqual(redo?.name, "puzzle_redo_started")
        XCTAssertEqual(redo?.parameters["completion_count"] as? String, "2")

        let recorded = PuzzleAnalyticsEventMapping.map(
            eventName: "puzzle_completion_recorded",
            category: .puzzles,
            metadata: ["completion_number": "3"],
            appVersion: "1.0.0"
        )
        XCTAssertEqual(recorded?.name, "puzzle_completion_recorded")
        XCTAssertEqual(recorded?.parameters["completion_number"] as? String, "3")
    }

    func testAnalyticsAllowlistsOnboardingCompleted() {
        let mapped = PuzzleAnalyticsEventMapping.map(
            eventName: "onboarding_completed",
            category: .app,
            metadata: [:],
            appVersion: "1.0.0"
        )
        XCTAssertEqual(mapped?.name, "onboarding_completed")
    }
}
