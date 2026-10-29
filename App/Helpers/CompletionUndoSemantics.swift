//
//  CompletionUndoSemantics.swift
//  Puzzle Buddy
//

import Foundation

struct CompletionUndoSnapshot: Equatable {
    let puzzleID: UUID
    let completionID: UUID
    let previousStatus: Puzzle.Status
    let previousProgressPercent: Int
    let recordedAt: Date

    func isActive(
        now: Date = Date(),
        window: TimeInterval = CompletionUndoSemantics.window
    ) -> Bool {
        now.timeIntervalSince(recordedAt) <= window
    }
}

enum CompletionUndoSemantics {
    static let window: TimeInterval = 5 * 60

    static func snapshot(
        puzzleID: UUID,
        completionID: UUID,
        previousStatus: Puzzle.Status,
        previousProgressPercent: Int,
        recordedAt: Date = Date()
    ) -> CompletionUndoSnapshot {
        CompletionUndoSnapshot(
            puzzleID: puzzleID,
            completionID: completionID,
            previousStatus: previousStatus,
            previousProgressPercent: PuzzleProgressSemantics.clamped(previousProgressPercent),
            recordedAt: recordedAt
        )
    }

    static func activeSnapshot(
        _ snapshot: CompletionUndoSnapshot?,
        puzzleID: UUID,
        now: Date = Date(),
        window: TimeInterval = window
    ) -> CompletionUndoSnapshot? {
        guard let snapshot, snapshot.puzzleID == puzzleID, snapshot.isActive(now: now, window: window) else {
            return nil
        }
        return snapshot
    }
}
