//
//  PuzzleDateSemantics.swift
//  Puzzle Buddy
//

import Foundation

// MARK: - PuzzleDateSemantics

enum PuzzleDateSemantics {
    static func detailDateLabel(for status: Puzzle.Status) -> String {
        switch status {
        case .wishlist:
            return "Added to wishlist"
        case .todo:
            return "Added"
        case .inProgress:
            return "Started"
        case .completed:
            return "Completed"
        }
    }

    static func formDateSectionTitle(for status: Puzzle.Status, puzzleName: String) -> String {
        let name = puzzleName.isEmpty ? "the puzzle" : puzzleName
        switch status {
        case .wishlist:
            return "Added to wishlist on"
        case .todo:
            return "Target date (optional)"
        case .inProgress:
            return "Started on"
        case .completed:
            return "When did you finish \(name)?"
        }
    }

    static func listTrailingDate(for puzzle: Puzzle) -> Date? {
        guard puzzle.status == .completed else { return nil }
        return puzzle.completionDate
    }

    static func statusPillLabel(for status: Puzzle.Status) -> String {
        switch status {
        case .wishlist:
            return "Wishlist"
        case .todo:
            return "To-Do"
        case .inProgress:
            return "In progress"
        case .completed:
            return "Completed"
        }
    }
}
