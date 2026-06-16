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
        isBypassAuthEnabled || ProcessInfo.processInfo.arguments.contains(disableFirebaseAnalytics)
    }

    static var shouldSeedPuzzles: Bool {
        ProcessInfo.processInfo.arguments.contains(seedPuzzles)
            || ProcessInfo.processInfo.environment["UI_TESTING_SEED_PUZZLES"] == "1"
    }

    @MainActor
    static func seedPuzzlesIfNeeded(into store: PuzzleStore) {
        guard shouldSeedPuzzles, store.puzzles.isEmpty else { return }
        let seeds = [
            Puzzle.fixture(name: "Mountain Sunset", pieces: 500, rating: .four),
            Puzzle.fixture(name: "Ocean Breeze", pieces: 1000, rating: .five)
        ]
        for puzzle in seeds {
            try? store.add(puzzle: puzzle)
        }
    }
}
