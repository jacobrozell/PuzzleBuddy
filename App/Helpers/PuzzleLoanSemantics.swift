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
