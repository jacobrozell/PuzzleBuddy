//
//  PuzzleCompletionSemantics.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleCompletionSemantics {
    static func makeCompletion(from puzzle: Puzzle, number: Int) -> PuzzleCompletion {
        PuzzleCompletion(
            completionNumber: number,
            startedAt: puzzle.startDate,
            completedAt: puzzle.completionDate,
            timeSpentHours: puzzle.estimatedTimeSpent?.hours,
            timeSpentMinutes: puzzle.estimatedTimeSpent?.minutes,
            rating: puzzle.rating == .none ? nil : puzzle.rating.rawValue
        )
    }

    static func sortedNewestFirst(_ completions: [PuzzleCompletion]) -> [PuzzleCompletion] {
        completions.sorted { $0.completionNumber > $1.completionNumber }
    }

    /// Keeps `completionNumber` sequential (1…N) by `completedAt` on existing SwiftData rows.
    static func renumberRecords(_ records: [PuzzleCompletionRecord]) {
        let sorted = records.sorted { lhs, rhs in
            if lhs.completedAt != rhs.completedAt {
                return lhs.completedAt < rhs.completedAt
            }
            return lhs.completionNumber < rhs.completionNumber
        }
        for (index, record) in sorted.enumerated() {
            record.completionNumber = index + 1
        }
    }
}
