//
//  OnboardingCopyTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class OnboardingCopyTests: XCTestCase {
    func testOnboardingHasFourPages() {
        XCTAssertEqual(OnboardingCopy.pages().count, 4)
    }

    func testCollectionPageMentionsOnLoan() {
        let page = OnboardingCopy.pages()[2]
        XCTAssertEqual(page.title, "Build Your Collection")
        XCTAssertTrue(page.message.localizedCaseInsensitiveContains("on loan"))
    }

    func testFinalPageMentionsUndoOrHistory() {
        let page = OnboardingCopy.pages().last
        XCTAssertEqual(page?.title, "Ready to Puzzle?")
        let message = page?.message ?? ""
        XCTAssertTrue(message.localizedCaseInsensitiveContains("undo") || message.localizedCaseInsensitiveContains("history"))
        XCTAssertTrue(message.localizedCaseInsensitiveContains("complete"))
    }

    func testWelcomePageUsesAppName() {
        let page = OnboardingCopy.pages(appName: "Puzzle Buddy")[0]
        XCTAssertTrue(page.title.contains("Puzzle Buddy"))
        XCTAssertTrue(page.message.localizedCaseInsensitiveContains("offline"))
    }
}
