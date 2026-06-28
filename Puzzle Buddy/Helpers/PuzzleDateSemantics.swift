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
        case .abandoned:
            return "Abandoned"
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
        case .abandoned:
            return "Abandoned on"
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
        case .abandoned:
            return "Abandoned"
        }
    }

    static func showsStartDatePicker(for status: Puzzle.Status) -> Bool {
        status == .inProgress || status == .completed
    }

    static func resolveStartDate(for puzzle: Puzzle) -> Date? {
        if let startDate = puzzle.startDate {
            return startDate
        }
        switch puzzle.status {
        case .inProgress, .completed:
            return puzzle.completionDate
        default:
            return nil
        }
    }

    static func progressDaysLabel(
        for puzzle: Puzzle,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> String? {
        guard let start = resolveStartDate(for: puzzle) else { return nil }
        switch puzzle.status {
        case .inProgress:
            let days = dayCount(from: start, to: now, calendar: calendar)
            return days == 1 ? "1 day puzzling" : "\(days) days puzzling"
        case .completed:
            let days = dayCount(from: start, to: puzzle.completionDate, calendar: calendar)
            if days == 0 { return "Finished same day" }
            return days == 1 ? "Finished in 1 day" : "Finished in \(days) days"
        default:
            return nil
        }
    }

    static func dayCount(from start: Date, to end: Date, calendar: Calendar = .current) -> Int {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        return max(calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0, 0)
    }

    static func completionDayCounts(for puzzles: [Puzzle], calendar: Calendar = .current) -> [Int] {
        puzzles.compactMap { puzzle -> Int? in
            guard puzzle.status == .completed,
                  let start = resolveStartDate(for: puzzle) else { return nil }
            return dayCount(from: start, to: puzzle.completionDate, calendar: calendar)
        }
    }
}
