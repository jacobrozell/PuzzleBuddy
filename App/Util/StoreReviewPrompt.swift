//
//  StoreReviewPrompt.swift
//  Puzzle Buddy
//
//  One-time StoreKit review request after a happy moment (scan or edit).
//  Settings uses a write-review URL instead of this prompt.
//

import Foundation
import StoreKit
import SwiftUI

enum StoreReviewPrompt {
    enum Reason: String {
        case barcodeScan = "barcode_scan"
        case puzzleEdited = "puzzle_edited"
        case settingsLink = "settings_link"
    }

    /// Marks the prompt as used and returns whether StoreKit should be invoked.
    /// The flag is set even if Apple later suppresses the dialog, so this fires once per install.
    static func consume(
        reason: Reason,
        userDefaults: UserDefaults = .standard,
        isUITesting: Bool = UITestSupport.isRunningUnderTest
    ) -> Bool {
        guard !isUITesting else { return false }
        guard !hasRequested(userDefaults: userDefaults) else { return false }
        userDefaults.set(true, forKey: UserPreferences.hasRequestedStoreReviewKey)
        AppLog.shared.info(
            .ui,
            eventName: "store_review_requested",
            message: "Requested App Store review prompt.",
            metadata: ["entry_point": reason.rawValue]
        )
        return true
    }

    /// Settings write-review is always available; recording it still blocks a later StoreKit prompt.
    static func recordSettingsLinkOpened(
        userDefaults: UserDefaults = .standard,
        isUITesting: Bool = UITestSupport.isRunningUnderTest
    ) {
        userDefaults.set(true, forKey: UserPreferences.hasRequestedStoreReviewKey)
        guard !isUITesting else { return }
        AppLog.shared.info(
            .ui,
            eventName: "store_review_link_opened",
            message: "Opened App Store write-review page from Settings.",
            metadata: ["entry_point": Reason.settingsLink.rawValue]
        )
    }

    @MainActor
    static func requestIfEligible(
        reason: Reason,
        requestReview: RequestReviewAction,
        delay: Duration = .milliseconds(1_500),
        userDefaults: UserDefaults = .standard,
        isUITesting: Bool = UITestSupport.isRunningUnderTest
    ) {
        guard consume(reason: reason, userDefaults: userDefaults, isUITesting: isUITesting) else { return }
        Task {
            try? await Task.sleep(for: delay)
            requestReview()
        }
    }

    static func hasRequested(userDefaults: UserDefaults = .standard) -> Bool {
        userDefaults.bool(forKey: UserPreferences.hasRequestedStoreReviewKey)
    }

    static func resetForTesting(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: UserPreferences.hasRequestedStoreReviewKey)
    }
}
