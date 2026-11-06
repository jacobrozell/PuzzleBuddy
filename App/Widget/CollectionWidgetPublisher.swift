//
//  CollectionWidgetPublisher.swift
//  Puzzle Buddy
//

import Foundation
import WidgetKit

enum CollectionWidgetSnapshotBuilder {
    static func make(from puzzles: [Puzzle], now: Date = Date()) -> CollectionWidgetSnapshot {
        let inProgress = puzzles.filter { $0.status == .inProgress }
        let featured = inProgress.max { rank($0) < rank($1) }
        let title = featured?.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let runningSince: Date? = {
            guard let since = featured?.timerRunningSince, since <= now else { return nil }
            return since
        }()
        var snapshot = CollectionWidgetSnapshot(
            inProgressCount: inProgress.count,
            todoCount: puzzles.filter { $0.status == .todo }.count,
            completedCount: puzzles.filter { $0.status == .completed }.count,
            wishlistCount: puzzles.filter { $0.status == .wishlist }.count,
            abandonedCount: puzzles.filter { $0.status == .abandoned }.count,
            onLoanCount: puzzles.filter(\.isOnLoan).count,
            featuredPuzzleID: featured?.id,
            featuredTitle: (title?.isEmpty == false) ? title : nil,
            featuredDetail: featured.flatMap { detail(for: $0) },
            featuredStartDate: featured?.startDate,
            featuredTimerAccumulatedSeconds: featured?.timerAccumulatedSeconds ?? 0,
            featuredTimerRunningSince: runningSince,
            updatedAt: now
        )
        snapshot.featuredStatus = snapshot.featuredStatusLine(at: now)
        return snapshot
    }

    private static func detail(for puzzle: Puzzle) -> String? {
        var parts: [String] = []
        if let pieces = puzzle.pieces, pieces > 0 {
            parts.append("\(pieces.formatted(.number)) pieces")
        }
        if puzzle.progressPercent > 0 {
            parts.append("\(puzzle.progressPercent)%")
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
