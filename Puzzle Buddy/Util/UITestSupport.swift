//
//  UITestSupport.swift
//  Puzzle Buddy
//
//  Launch arguments for UI tests and simulator audits.
//

import Foundation

enum UITestSupport {
    static let bypassAuth = "-ui_testing_bypass_auth"
    static let seedPuzzles = "-ui_testing_seed_puzzles"
    static let disableFirebaseAnalytics = "-disable_firebase_analytics"

    static var isBypassAuthEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(bypassAuth)
            || ProcessInfo.processInfo.environment["UI_TESTING_BYPASS_AUTH"] == "1"
    }

    static var isRunningUnderTest: Bool {
        isBypassAuthEnabled
            || ProcessInfo.processInfo.arguments.contains(disableFirebaseAnalytics)
            || ProcessInfo.processInfo.arguments.contains(seedPuzzles)
            || ProcessInfo.processInfo.environment["UI_TESTING_SEED_PUZZLES"] == "1"
    }

    static var shouldSeedPuzzles: Bool {
        ProcessInfo.processInfo.arguments.contains(seedPuzzles)
            || ProcessInfo.processInfo.environment["UI_TESTING_SEED_PUZZLES"] == "1"
            || ProcessInfo.processInfo.arguments.contains(disableFirebaseAnalytics)
    }

    @MainActor
    static func seedPuzzlesIfNeeded(into store: PuzzleStore) {
        guard shouldSeedPuzzles, store.puzzles.isEmpty else { return }
        try? store.loadDemoPuzzles()
    }
}
