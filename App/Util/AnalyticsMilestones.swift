//
//  AnalyticsMilestones.swift
//  Puzzle Buddy
//

import Foundation

/// Fires `milestone_reached` once per milestone id (analytics-only ack, separate from UI banners).
enum AnalyticsMilestones {
    private static let storageKey = "PuzzleBuddy.AnalyticsLoggedMilestones"

    static func logIfNeeded(milestoneID: String) {
        guard !milestoneID.isEmpty else { return }
        var logged = loadLogged()
        guard !logged.contains(milestoneID) else { return }
        logged.insert(milestoneID)
        UserDefaults.standard.set(Array(logged), forKey: storageKey)

        AppLog.shared.info(
            .app,
            eventName: "milestone_reached",
            message: "Collection milestone reached.",
            metadata: ["milestone_id": milestoneID]
        )
    }

    static func logCollectionSizeMilestones(puzzleCount: Int) {
        if puzzleCount >= 1 { logIfNeeded(milestoneID: "first_puzzle") }
        if puzzleCount >= 10 { logIfNeeded(milestoneID: "ten_puzzles") }
    }

    static func logCompletionMilestones(completedCount: Int) {
        if completedCount >= 1 { logIfNeeded(milestoneID: "first_completion") }
        if completedCount >= 5 { logIfNeeded(milestoneID: "five_completions") }
        if completedCount >= 10 { logIfNeeded(milestoneID: "completed_10") }
    }

    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    private static func loadLogged() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: storageKey) ?? [])
    }
}
