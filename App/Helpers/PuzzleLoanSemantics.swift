//
//  PuzzleLoanSemantics.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleLoanSemantics {
    /// Dispositions that mean the puzzle is no longer expected back.
    static func dispositionEndsOwnership(_ disposition: PuzzleDisposition) -> Bool {
        switch disposition {
        case .gifted, .sold, .donated, .trashed:
            return true
        case .none, .kept:
            return false
        }
    }

    /// A due date is overdue after that calendar day ends — due today is still on time.
    static func isOverdue(
        _ puzzle: Puzzle,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard puzzle.isOnLoan, let dueBackDate = puzzle.dueBackDate else { return false }
        return calendar.startOfDay(for: dueBackDate) < calendar.startOfDay(for: now)
    }

    static func listBadgeTitle(
        for puzzle: Puzzle,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        isOverdue(puzzle, now: now, calendar: calendar) ? "Overdue" : "On loan"
    }

    static func listBadgeAccessibilityLabel(
        for puzzle: Puzzle,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        if isOverdue(puzzle, now: now, calendar: calendar), let dueBackDate = puzzle.dueBackDate {
            return "Overdue, due \(dueBackDate.formatted(date: .abbreviated, time: .omitted))"
        }
        if let name = puzzle.loanedToDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return "On loan to \(name)"
        }
        return "On loan"
    }

    static func dueBackDisplayValue(
        for puzzle: Puzzle,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String? {
        guard let dueBackDate = puzzle.dueBackDate else { return nil }
        let date = dueBackDate.formatted(date: .abbreviated, time: .omitted)
        if isOverdue(puzzle, now: now, calendar: calendar) {
            return "\(date) · Overdue"
        }
        return date
    }

    static func clearLoan(on puzzle: Puzzle) {
        puzzle.isOnLoan = false
        puzzle.loanedToFriendID = nil
        puzzle.loanedToDisplayName = nil
        puzzle.loanedAt = nil
        puzzle.dueBackDate = nil
        puzzle.lastLoanNudgeAt = nil
    }

    /// Applies disposition / off rules, then sets `loanedAt` and normalized display name.
    /// Caller assigns `loanedToFriendID` from the display name (find-or-create).
    static func prepareLoanState(puzzle: Puzzle, now: Date = Date()) {
        if dispositionEndsOwnership(puzzle.disposition) {
            clearLoan(on: puzzle)
            return
        }

        if !puzzle.isOnLoan {
            clearLoan(on: puzzle)
            return
        }

        if puzzle.loanedAt == nil {
            puzzle.loanedAt = now
        }

        puzzle.loanedToDisplayName = FriendSemantics.normalizedDisplayName(puzzle.loanedToDisplayName)
    }
}
