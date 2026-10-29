//
//  PuzzleTimerSemantics.swift
//  Puzzle Buddy
//
//  Wall-clock stopwatch for In-Progress puzzles. The store persists the anchor; the UI ticks.
//

import Foundation

enum PuzzleTimerSemantics {
    enum PauseReason: String {
        case pause
        case reset
        case otherStarted = "other_started"
        case statusLeft = "status_left"
    }

    /// A running anchor in the future means the clock moved backward.
    static func isClockSkewed(runningSince: Date?, now: Date) -> Bool {
        guard let runningSince else { return false }
        return now < runningSince
    }

    static func isRunning(runningSince: Date?, now: Date) -> Bool {
        runningSince != nil && !isClockSkewed(runningSince: runningSince, now: now)
    }

    static func elapsedSeconds(accumulated: Int, runningSince: Date?, now: Date) -> Int {
        let base = max(accumulated, 0)
        guard let runningSince, !isClockSkewed(runningSince: runningSince, now: now) else { return base }
        return base + Int(now.timeIntervalSince(runningSince))
    }

    static func elapsedSeconds(for puzzle: Puzzle, now: Date) -> Int {
        elapsedSeconds(
            accumulated: puzzle.timerAccumulatedSeconds,
            runningSince: puzzle.timerRunningSince,
            now: now
        )
    }

    /// Folds the open segment into the accumulator. A backward clock drops the open segment.
    static func pause(_ puzzle: Puzzle, now: Date) {
        puzzle.timerAccumulatedSeconds = elapsedSeconds(for: puzzle, now: now)
        puzzle.timerRunningSince = nil
    }

    /// Other puzzles that must pause before `startingID` starts.
    static func idsToPause(startingID: UUID, in puzzles: [Puzzle]) -> [UUID] {
        puzzles
            .filter { $0.id != startingID && $0.timerRunningSince != nil }
            .map(\.id)
    }

    /// Nearest minute; any positive total under 30 seconds logs as 1 minute. Zero is nil.
    static func roundedMinutes(seconds: Int) -> Int? {
        guard seconds > 0 else { return nil }
        return max(1, Int((Double(seconds) / 60).rounded()))
    }

    static func puzzleTime(seconds: Int) -> Puzzle.PuzzleTime? {
        guard let minutes = roundedMinutes(seconds: seconds) else { return nil }
        return Puzzle.PuzzleTime(hours: minutes / 60, minutes: minutes % 60)
    }

    /// Logged time to write on first completion: only when the timer ran and nothing was entered.
    static func completionPrefill(timerSeconds: Int, logged: Puzzle.PuzzleTime?) -> Puzzle.PuzzleTime? {
        guard logged?.hours == nil, logged?.minutes == nil else { return nil }
        return puzzleTime(seconds: timerSeconds)
    }

    /// Suggestion for the form's “Use timer time” row; nil when it already matches.
    static func formSuggestion(timerSeconds: Int, logged: Puzzle.PuzzleTime?) -> Puzzle.PuzzleTime? {
        guard let suggestion = puzzleTime(seconds: timerSeconds) else { return nil }
        guard totalMinutes(suggestion) != totalMinutes(logged) else { return nil }
        return suggestion
    }

    static func durationBucket(seconds: Int) -> String {
        switch seconds {
        case ..<900: return "under_15m"
        case ..<3_600: return "15m_1h"
        case ..<10_800: return "1h_3h"
        default: return "over_3h"
        }
    }

    /// `H:MM:SS`; hours are not capped at 24.
    static func clockLabel(seconds: Int) -> String {
        let total = max(seconds, 0)
        return String(format: "%d:%02d:%02d", total / 3_600, (total % 3_600) / 60, total % 60)
    }

    static func spokenLabel(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .dropAll
        guard seconds > 0 else { return "0 seconds" }
        return formatter.string(from: TimeInterval(seconds)) ?? clockLabel(seconds: seconds)
    }

    private static func totalMinutes(_ time: Puzzle.PuzzleTime?) -> Int {
        max(time?.hours ?? 0, 0) * 60 + max(time?.minutes ?? 0, 0)
    }
}
