//
//  StoreReviewPromptTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class StoreReviewPromptTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "StoreReviewPromptTests.\(UUID().uuidString)")
        StoreReviewPrompt.resetForTesting(userDefaults: defaults)
    }

    override func tearDown() {
        StoreReviewPrompt.resetForTesting(userDefaults: defaults)
        defaults = nil
        super.tearDown()
    }

    func testConsumeAllowsOneRequest() {
        XCTAssertTrue(
            StoreReviewPrompt.consume(
                reason: .barcodeScan,
                userDefaults: defaults,
                isUITesting: false
            )
        )
        XCTAssertTrue(StoreReviewPrompt.hasRequested(userDefaults: defaults))
        XCTAssertFalse(
            StoreReviewPrompt.consume(
                reason: .puzzleEdited,
                userDefaults: defaults,
                isUITesting: false
            )
        )
    }

    func testConsumeSkipsDuringUITesting() {
        XCTAssertFalse(
            StoreReviewPrompt.consume(
                reason: .barcodeScan,
                userDefaults: defaults,
                isUITesting: true
            )
        )
        XCTAssertFalse(StoreReviewPrompt.hasRequested(userDefaults: defaults))
    }

    func testSettingsLinkBlocksLaterPrompt() {
        StoreReviewPrompt.recordSettingsLinkOpened(userDefaults: defaults, isUITesting: false)
        XCTAssertTrue(StoreReviewPrompt.hasRequested(userDefaults: defaults))
        XCTAssertFalse(
            StoreReviewPrompt.consume(
                reason: .barcodeScan,
                userDefaults: defaults,
                isUITesting: false
            )
        )
    }

    func testWriteReviewURLUsesAppStoreID() {
        XCTAssertEqual(AppLinks.appStoreID, "1642548378")
        XCTAssertEqual(
            AppLinks.appStoreWriteReview.absoluteString,
            "https://apps.apple.com/app/id1642548378?action=write-review"
        )
    }
}
