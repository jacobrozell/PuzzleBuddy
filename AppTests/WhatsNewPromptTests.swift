//
//  WhatsNewPromptTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class WhatsNewPromptTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "WhatsNewPromptTests.\(UUID().uuidString)")
        WhatsNewPrompt.resetForTesting(userDefaults: defaults)
    }

    override func tearDown() {
        WhatsNewPrompt.resetForTesting(userDefaults: defaults)
        defaults = nil
        super.tearDown()
    }

    func testPresentsForUpgraderWhoHasNotSeenNotes() {
        XCTAssertTrue(
            WhatsNewPrompt.shouldPresent(
                onboardingComplete: true,
                seenVersion: nil,
                isUITesting: false,
                isMarketingCapture: false
            )
        )
    }

    func testSkipsFirstRunUntilOnboardingFinishes() {
        XCTAssertFalse(
            WhatsNewPrompt.shouldPresent(
                onboardingComplete: false,
                seenVersion: nil,
                isUITesting: false,
                isMarketingCapture: false
            )
        )
    }

    func testSkipsAfterNotesHaveBeenSeen() {
        WhatsNewPrompt.markSeen(userDefaults: defaults)
        XCTAssertFalse(
            WhatsNewPrompt.shouldPresent(
                onboardingComplete: true,
                seenVersion: WhatsNewPrompt.seenVersion(userDefaults: defaults),
                isUITesting: false,
                isMarketingCapture: false
            )
        )
    }

    func testSkipsDuringUITestingAndMarketingCapture() {
        XCTAssertFalse(
            WhatsNewPrompt.shouldPresent(
                onboardingComplete: true,
                seenVersion: nil,
                isUITesting: true,
                isMarketingCapture: false
            )
        )
        XCTAssertFalse(
            WhatsNewPrompt.shouldPresent(
                onboardingComplete: true,
                seenVersion: nil,
                isUITesting: false,
                isMarketingCapture: true
            )
        )
    }

    func testVersionCompareTreatsMissingAsOlder() {
        XCTAssertTrue(WhatsNewPrompt.isVersion(nil, olderThan: "1.1.0"))
        XCTAssertTrue(WhatsNewPrompt.isVersion("1.0.0", olderThan: "1.1.0"))
        XCTAssertFalse(WhatsNewPrompt.isVersion("1.1.0", olderThan: "1.1.0"))
        XCTAssertFalse(WhatsNewPrompt.isVersion("1.2.0", olderThan: "1.1.0"))
    }

    func testCopyMentionsHistoryLoanAndRedo() {
        let joined = WhatsNewCopy.items.map { "\($0.title) \($0.message)" }.joined(separator: " ")
        XCTAssertTrue(joined.localizedCaseInsensitiveContains("finish"))
        XCTAssertTrue(joined.localizedCaseInsensitiveContains("loan"))
        XCTAssertTrue(joined.localizedCaseInsensitiveContains("again"))
        XCTAssertEqual(WhatsNewCopy.items.count, 3)
    }
}
