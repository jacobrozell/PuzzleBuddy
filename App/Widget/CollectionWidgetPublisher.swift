//
//  CollectionWidgetPublisher.swift
//  Puzzle Buddy
//

import Foundation
import WidgetKit

enum CollectionWidgetSnapshotBuilder {
    static func make(
        from puzzles: [Puzzle],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> CollectionWidgetSnapshot {
        let inProgress = puzzles.filter { $0.status == .inProgress }
        let working = inProgress.max { rank($0) < rank($1) }
        let featured = working ?? nextTodo(from: puzzles)
        let isBacklog = featured?.status == .todo
        let title = featured?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let runningSince: Date? = {
            guard !isBacklog, let since = featured?.timerRunningSince, since <= now else { return nil }
            return since
        }()
        let stats = CollectionStats.compute(from: puzzles, calendar: calendar, now: now)
        var snapshot = CollectionWidgetSnapshot(
            inProgressCount: inProgress.count,
            todoCount: puzzles.filter { $0.status == .todo }.count,
            completedCount: puzzles.filter { $0.status == .completed }.count,
            wishlistCount: puzzles.filter { $0.status == .wishlist }.count,
            abandonedCount: puzzles.filter { $0.status == .abandoned }.count,
            onLoanCount: puzzles.filter(\.isOnLoan).count,
            featuredProgressPercent: isBacklog ? 0 : (featured.map { min(max($0.progressPercent, 0), 100) } ?? 0),
            completionsThisMonth: stats.completionsThisMonth,
            completionsThisYear: stats.completionsThisYear,
            completionsByMonth: stats.completionsByMonthThisYear,
            activityYear: calendar.component(.year, from: now),
            currentMonthIndex: max(calendar.component(.month, from: now) - 1, 0),
            totalPiecesCompleted: stats.totalPiecesCompleted,
            totalMinutesPuzzling: stats.totalMinutesPuzzling,
            insightLines: insightLines(from: stats),
            paceLabels: stats.paceBuckets.map(\.label),
            paceCounts: stats.paceBuckets.map(\.count),
            featuredIsBacklog: isBacklog,
            featuredPuzzleID: featured?.id,
            featuredTitle: (title?.isEmpty == false) ? title : nil,
            featuredDetail: featured.flatMap { detail(for: $0) },
            featuredStartDate: isBacklog ? nil : featured?.startDate,
            featuredTimerAccumulatedSeconds: isBacklog ? 0 : (featured?.timerAccumulatedSeconds ?? 0),
            featuredTimerRunningSince: runningSince,
            updatedAt: now
        )
        if isBacklog {
            snapshot.featuredStatus = "Up next"
        } else {
            snapshot.featuredStatus = snapshot.featuredStatusLine(at: now)
        }
        return snapshot
    }

    /// A named to-do that is not on loan, so the widget can suggest one when the table is clear.
    private static func nextTodo(from puzzles: [Puzzle]) -> Puzzle? {
        let available = puzzles.filter { $0.status == .todo && !$0.isOnLoan }
        return available.min { lhs, rhs in
            let left = lhs.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let right = rhs.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let leftRank = left.isEmpty ? 1 : 0
            let rightRank = right.isEmpty ? 1 : 0
            if leftRank != rightRank { return leftRank < rightRank }
            let order = left.localizedCaseInsensitiveCompare(right)
            if order != .orderedSame { return order == .orderedAscending }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    private static func insightLines(from stats: CollectionStats) -> [String] {
        var lines: [String] = []
        if let percent = stats.averageInProgressPercent {
            lines.append("\(percent)% along")
        }
        if stats.missingPiecesCount == 1 {
            lines.append("1 with missing pieces")
        } else if stats.missingPiecesCount > 1 {
            lines.append("\(stats.missingPiecesCount) with missing pieces")
        }
        if let rating = stats.formattedAverageRating {
            lines.append("\(rating) avg rating")
        }
        if let days = stats.formattedAverageDaysToComplete {
            lines.append("\(days) to finish")
        }
        if let favorite = stats.favoritePieceCount {
            lines.append("Usually \(favorite.formatted(.number)) pieces")
        }
        if let speed = stats.formattedAverageSpeed {
            lines.append(speed)
        }
        if stats.replayedPuzzleCount == 1 {
            lines.append("1 replay")
        } else if stats.replayedPuzzleCount > 1 {
            lines.append("\(stats.replayedPuzzleCount) replays")
        }
        if let best = stats.mostProductiveMonthThisYear {
            lines.append("Busiest: \(best.label)")
        }
        if let type = stats.favoritePuzzleType {
            lines.append("Mostly \(type.displayLabel)")
        }
        if let brand = stats.favoriteBrand {
            lines.append("Mostly \(brand)")
        }
        return lines
    }

    private static func detail(for puzzle: Puzzle) -> String? {
        var parts: [String] = []
        if let pieces = puzzle.pieces, pieces > 0 {
            parts.append("\(pieces.formatted(.number)) pieces")
        }
        if puzzle.progressPercent > 0 {
            parts.append("\(puzzle.progressPercent)%")
        }
        if puzzle.hasMissingPieces {
            parts.append("Missing pieces")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// Running timer first, then the latest start, then name.
    private static func rank(_ puzzle: Puzzle) -> (Int, TimeInterval, String) {
        let running = puzzle.timerRunningSince == nil ? 0 : 1
        let stamp = (puzzle.timerRunningSince ?? puzzle.startDate)?.timeIntervalSince1970 ?? 0
        return (running, stamp, puzzle.name)
    }
}

enum CollectionWidgetPublisher {
    static func publish(from puzzles: [Puzzle], now: Date = Date()) {
        let snapshot = CollectionWidgetSnapshotBuilder.make(from: puzzles, now: now)
        CollectionWidgetSnapshotStore.publish(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: CollectionWidgetSnapshotStore.kind)
        WidgetCenter.shared.reloadTimelines(ofKind: CollectionWidgetSnapshotStore.glanceKind)
    }
}
