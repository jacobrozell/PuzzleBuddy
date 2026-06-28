//
//  CollectionMilestones.swift
//  Puzzle Buddy
//

import Foundation

// MARK: - CollectionMilestone

struct CollectionMilestone: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String
}

// MARK: - CollectionMilestones

enum CollectionMilestones {
    static let storageKey = "PuzzleBuddy.AcknowledgedMilestones"

    static func newlyEarned(
        stats: CollectionStats,
        excludingDemo: Bool = true,
        previouslyAcknowledged: Set<String>
    ) -> [CollectionMilestone] {
        earned(from: stats, excludingDemo: excludingDemo)
            .filter { !previouslyAcknowledged.contains($0.id) }
    }

    static func earned(from stats: CollectionStats, excludingDemo: Bool = true) -> [CollectionMilestone] {
        var milestones: [CollectionMilestone] = []

        if stats.completedCount >= 1 {
            milestones.append(.init(
                id: "completed_1",
                title: "First puzzle completed!",
                subtitle: "Your collection journey begins.",
                icon: "checkmark.seal.fill"
            ))
        }
        if stats.completedCount >= 10 {
            milestones.append(.init(
                id: "completed_10",
                title: "10 puzzles completed!",
                subtitle: "Double digits at the table.",
                icon: "star.circle.fill"
            ))
        }
        if stats.completedCount >= 50 {
            milestones.append(.init(
                id: "completed_50",
                title: "50 puzzles completed!",
                subtitle: "Serious collector status.",
                icon: "crown.fill"
            ))
        }
        if stats.totalPiecesCompleted >= 10_000 {
            milestones.append(.init(
                id: "pieces_10000",
                title: "10,000 pieces assembled!",
                subtitle: "That's a lot of edge pieces.",
                icon: "puzzlepiece.extension.fill"
            ))
        }
        if stats.totalPiecesCompleted >= 50_000 {
            milestones.append(.init(
                id: "pieces_50000",
                title: "50,000 pieces assembled!",
                subtitle: "Legendary puzzler.",
                icon: "sparkles"
            ))
        }
        if stats.totalMinutesPuzzling >= 6_000 {
            milestones.append(.init(
                id: "hours_100",
                title: "100 hours at the table!",
                subtitle: "Time well puzzled.",
                icon: "clock.fill"
            ))
        }
        if stats.completionsThisYear >= 12 {
            milestones.append(.init(
                id: "year_completions_12",
                title: "12 puzzles this year!",
                subtitle: "A puzzle a month pace.",
                icon: "calendar"
            ))
        }

        return milestones
    }

    static func loadAcknowledged() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: storageKey) ?? [])
    }

    static func acknowledge(_ milestoneID: String) {
        var set = loadAcknowledged()
        set.insert(milestoneID)
        UserDefaults.standard.set(Array(set), forKey: storageKey)
    }
}
