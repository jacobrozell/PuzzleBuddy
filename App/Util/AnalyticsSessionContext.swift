//
//  AnalyticsSessionContext.swift
//  Puzzle Buddy
//

import Foundation

/// Once-per-cold-start session snapshot + days-since-last-open bucket.
enum AnalyticsSessionContext {
    private static let lastOpenKey = "PuzzleBuddy.AnalyticsLastOpenAt"
    private static var didLogSnapshot = false
    private static var pendingDaysBucket: String?

    static func beginSession() {
        guard pendingDaysBucket == nil else { return }
        pendingDaysBucket = consumeDaysSinceLastOpenBucket()
    }

    static func logSnapshotIfNeeded(puzzles: [Puzzle]) {
        guard !didLogSnapshot else { return }
        didLogSnapshot = true

        var metadata = PuzzleAnalyticsMetadata.collectionSnapshotMetadata(for: puzzles)
        metadata["days_since_last_open_bucket"] = pendingDaysBucket
            ?? PuzzleAnalyticsMetadata.daysSinceLastOpenBucket(days: nil)

        AppLog.shared.info(
            .app,
            eventName: "session_snapshot",
            message: "Session collection snapshot.",
            metadata: metadata
        )
        AnalyticsUserContext.syncCollection(from: puzzles)
    }

    /// Test seam — resets in-memory session guards.
    static func resetForTesting() {
        didLogSnapshot = false
        pendingDaysBucket = nil
    }

    private static func consumeDaysSinceLastOpenBucket() -> String {
        let now = Date()
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: lastOpenKey) as? Date
        let bucket: String
        if let previous {
            let days = Calendar.current.dateComponents([.day], from: previous, to: now).day ?? 0
            bucket = PuzzleAnalyticsMetadata.daysSinceLastOpenBucket(days: max(0, days))
        } else {
            bucket = PuzzleAnalyticsMetadata.daysSinceLastOpenBucket(days: nil)
        }
        defaults.set(now, forKey: lastOpenKey)
        return bucket
    }
}
