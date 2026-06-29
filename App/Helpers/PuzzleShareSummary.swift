//
//  PuzzleShareSummary.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleShareSummary {
    static func make(from stats: CollectionStats, puzzles: [Puzzle]) -> String {
        var lines = [
            "My \(AppInfo.displayName) collection",
            statsLine(for: stats)
        ]

        let featured = puzzles
            .sorted { lhs, rhs in
                if lhs.image != nil && rhs.image == nil { return true }
                if lhs.image == nil && rhs.image != nil { return false }
                return lhs.completionDate > rhs.completionDate
            }
            .prefix(6)
            .map(\.name)
            .filter { !$0.isEmpty }

        if !featured.isEmpty {
            lines.append(featured.joined(separator: " · "))
        }

        lines.append("Tracked with Puzzle Buddy")
        return lines.joined(separator: "\n")
    }

    static func statsLine(for stats: CollectionStats) -> String {
        var parts = ["\(stats.totalCount) puzzles"]

        if stats.completedCount > 0 {
            parts.append("\(stats.completedCount) completed")
        }
        if stats.inProgressCount > 0 {
            parts.append("\(stats.inProgressCount) in progress")
        }
        if stats.backlogCount > 0 {
            parts.append("\(stats.backlogCount) on the shelf")
        }

        return parts.joined(separator: " · ")
    }
}
