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
}
