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
}
