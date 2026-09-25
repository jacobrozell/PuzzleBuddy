//
//  WhatsNewPrompt.swift
//  Puzzle Buddy
//
//  One-time 1.1.0 notes for users who already finished 1.0 onboarding.
//

import Foundation

enum WhatsNewPrompt {
    static let notesVersion = "1.1.0"

    static func shouldPresent(
        onboardingComplete: Bool,
        seenVersion: String?,
        notesVersion: String = notesVersion,
        isUITesting: Bool = UITestSupport.isRunningUnderTest,
        isMarketingCapture: Bool = MarketingSnapshotBootstrap.isMarketingCapture
    ) -> Bool {
        guard !isUITesting else { return false }
        guard !isMarketingCapture else { return false }
        guard onboardingComplete else { return false }
        return isVersion(seenVersion, olderThan: notesVersion)
    }

    static func shouldPresent(userDefaults: UserDefaults = .standard) -> Bool {
        shouldPresent(
            onboardingComplete: OnboardingStorage.isComplete,
            seenVersion: seenVersion(userDefaults: userDefaults)
        )
    }

    static func seenVersion(userDefaults: UserDefaults = .standard) -> String? {
        userDefaults.string(forKey: UserPreferences.whatsNewSeenVersionKey)
    }

    static func markSeen(
        notesVersion: String = notesVersion,
        userDefaults: UserDefaults = .standard
    ) {
        userDefaults.set(notesVersion, forKey: UserPreferences.whatsNewSeenVersionKey)
    }

    static func resetForTesting(userDefaults: UserDefaults = .standard) {
        userDefaults.removeObject(forKey: UserPreferences.whatsNewSeenVersionKey)
    }

    static func isVersion(_ lhs: String?, olderThan rhs: String) -> Bool {
        guard let lhs else { return true }
        return compareVersions(lhs, rhs) == .orderedAscending
    }

    static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = versionComponents(lhs)
        let right = versionComponents(rhs)
        let count = max(left.count, right.count)
        for index in 0..<count {
            let a = index < left.count ? left[index] : 0
            let b = index < right.count ? right[index] : 0
            if a < b { return .orderedAscending }
            if a > b { return .orderedDescending }
        }
        return .orderedSame
    }

    private static func versionComponents(_ version: String) -> [Int] {
        version.split(separator: ".").compactMap { Int($0) }
    }
}

enum WhatsNewCopy {
    struct Item: Equatable, Identifiable {
        let id: String
        let title: String
        let message: String
        let symbolName: String
    }

    static let title = "What's New in 1.1"
    static let subtitle = "A few upgrades for the collection you already keep."
    static let dismissTitle = "Got it"

    static let items: [Item] = [
        Item(
            id: "history",
            title: "Fix a finish",
            message: "Edit or delete a completion if you tapped Complete by accident.",
            symbolName: "clock.arrow.circlepath"
        ),
        Item(
            id: "loan",
            title: "On loan",
            message: "Track boxes you’ve lent out, and see when they’re overdue.",
            symbolName: "person.fill.checkmark"
        ),
        Item(
            id: "redo",
            title: "Puzzle again",
            message: "Start another go without losing the finishes you already logged.",
            symbolName: "arrow.counterclockwise"
        ),
    ]
}
