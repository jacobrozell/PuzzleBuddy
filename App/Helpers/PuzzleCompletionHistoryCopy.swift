//
//  PuzzleCompletionHistoryCopy.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleCompletionHistoryCopy {
    static let swipeRemoveTitle = "Remove"
    static let swipeEditTitle = "Edit"
    static let deleteDialogTitle = "Remove completion?"
    static let lastCompletionStatusPrompt = "This was your only completion log. Choose a new status for the puzzle."

    static func supportsSwipeActions(completionCount: Int) -> Bool {
        completionCount > 0
    }

    static func deleteDialogMessage(
        completionNumber: Int,
        completedAt: Date,
        remainingCount: Int
    ) -> String {
        let date = completedAt.formatted(date: .abbreviated, time: .omitted)
        if remainingCount <= 1 {
            return "Remove the finish log from \(date)?"
        }
        return "Remove completion #\(completionNumber) from \(date)? Other finishes stay in your history."
    }
}
