//
//  CollectionStats.swift
//  Puzzle Buddy
//

import Foundation

// MARK: - CollectionStats

struct CollectionStats: Equatable {
    let totalCount: Int
    let completedCount: Int
    let inProgressCount: Int
    let wishlistCount: Int
    let abandonedCount: Int
    let totalPiecesCompleted: Int
    let totalMinutesPuzzling: Int
    let backlogCount: Int
    let missingPiecesCount: Int
    let averageRating: Double?
    let favoritePieceCount: Int?
    let averageDaysToComplete: Double?
    let favoritePuzzleType: PuzzleType?
    let topPurchaseLocations: [String]
    let completionsThisMonth: Int
    let completionsThisYear: Int
    let biggestCompletedPieces: Int?
    let smallestCompletedPieces: Int?
    let topTags: [PuzzleTagCount]

    static func compute(
        from puzzles: [Puzzle],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> CollectionStats {
        let completed = puzzles.filter { $0.status == .completed }
        let todo = puzzles.filter { $0.status == .todo }
        let inProgress = puzzles.filter { $0.status == .inProgress }
        let wishlist = puzzles.filter { $0.status == .wishlist }
        let abandoned = puzzles.filter { $0.status == .abandoned }
        let missingPieces = puzzles.filter(\.hasMissingPieces)

        let pieceCounts = completed.compactMap(\.pieces)
        let ratedCompleted = completed.filter { $0.rating != .none }

        let averageRating: Double? = {
            guard !ratedCompleted.isEmpty else { return nil }
            let sum = ratedCompleted.reduce(0.0) { $0 + $1.rating.rawValue }
            return sum / Double(ratedCompleted.count)
        }()

        let totalMinutes = completed.reduce(0) { partial, puzzle in
            partial + minutesSpent(on: puzzle)
        }

        let dayCounts = PuzzleDateSemantics.completionDayCounts(for: completed, calendar: calendar)
        let averageDays: Double? = {
            guard !dayCounts.isEmpty else { return nil }
            return Double(dayCounts.reduce(0, +)) / Double(dayCounts.count)
        }()

        return CollectionStats(
            totalCount: puzzles.count,
            completedCount: completed.count,
            inProgressCount: inProgress.count,
            wishlistCount: wishlist.count,
            abandonedCount: abandoned.count,
            totalPiecesCompleted: pieceCounts.reduce(0, +),
            totalMinutesPuzzling: totalMinutes,
            backlogCount: todo.count,
            missingPiecesCount: missingPieces.count,
            averageRating: averageRating,
            favoritePieceCount: favoritePieceCount(from: pieceCounts),
            averageDaysToComplete: averageDays,
            favoritePuzzleType: favoritePuzzleType(from: completed),
            topPurchaseLocations: topPurchaseLocations(from: puzzles, limit: 3),
            completionsThisMonth: completionCount(
                in: completed,
                calendar: calendar,
                now: now,
                component: .month
            ),
            completionsThisYear: completionCount(
                in: completed,
                calendar: calendar,
                now: now,
                component: .year
            ),
            biggestCompletedPieces: pieceCounts.max(),
            smallestCompletedPieces: pieceCounts.min(),
            topTags: PuzzleTagIndex.counts(from: puzzles, limit: 5)
        )
    }

    // MARK: - Display formatting

    var formattedTotalHours: String {
        Self.formatHours(fromMinutes: totalMinutesPuzzling)
    }

    var formattedAverageRating: String? {
        guard let averageRating else { return nil }
        return String(format: "%.1f", averageRating)
    }

    var formattedAverageDaysToComplete: String? {
        Self.formatAverageDays(averageDaysToComplete)
    }

    static func formatAverageDays(_ value: Double?) -> String? {
        guard let value else { return nil }
        let rounded = value.rounded()
        if rounded >= 14 {
            let weeks = (rounded / 7).rounded()
            return weeks == 1 ? "About 1 week" : "About \(Int(weeks)) weeks"
        }
        if rounded <= 1 {
            return "About 1 day"
        }
        return "About \(Int(rounded)) days"
    }

    static func formatHours(fromMinutes minutes: Int) -> String {
        guard minutes > 0 else { return "0 hours" }
        let hours = Double(minutes) / 60.0
        if hours >= 10 {
            return "\(Int(hours.rounded())) hours"
        }
        if hours >= 1 {
            let rounded = (hours * 10).rounded() / 10
            if rounded == rounded.rounded() {
                return "\(Int(rounded)) hours"
            }
            return String(format: "%.1f hours", rounded)
        }
        return "\(minutes) minutes"
    }

    static func formatPieceCount(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    // MARK: - Private helpers

    private static func minutesSpent(on puzzle: Puzzle) -> Int {
        guard let time = puzzle.estimatedTimeSpent,
              let hours = time.hours,
              let minutes = time.minutes else {
            return 0
        }
        return max((hours * 60) + minutes, 0)
    }

    private static func completionCount(
        in completed: [Puzzle],
        calendar: Calendar,
        now: Date,
        component: Calendar.Component
    ) -> Int {
        completed.filter { puzzle in
            calendar.isDate(puzzle.completionDate, equalTo: now, toGranularity: component)
        }.count
    }

    static func favoritePieceCount(from counts: [Int]) -> Int? {
        guard !counts.isEmpty else { return nil }

        let frequencies = Dictionary(grouping: counts, by: { $0 }).mapValues(\.count)
        let maxFrequency = frequencies.values.max() ?? 0
        let modes = frequencies.filter { $0.value == maxFrequency }.keys.sorted()

        if modes.count == 1 {
            return modes[0]
        }
        return median(counts)
    }

    private static func median(_ values: [Int]) -> Int {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }

    private static func favoritePuzzleType(from completed: [Puzzle]) -> PuzzleType? {
        let types = completed.map(\.puzzleType).filter { $0 != .none }
        guard !types.isEmpty else { return nil }
        let frequencies = Dictionary(grouping: types, by: { $0 }).mapValues(\.count)
        return frequencies.max(by: { $0.value < $1.value })?.key
    }

    private static func topPurchaseLocations(from puzzles: [Puzzle], limit: Int) -> [String] {
        let locations = puzzles.compactMap(\.purchaseLocation).filter { !$0.isEmpty }
        guard !locations.isEmpty else { return [] }
        let frequencies = Dictionary(grouping: locations, by: { $0 }).mapValues(\.count)
        return frequencies
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending
                }
                return lhs.value > rhs.value
            }
            .prefix(limit)
            .map(\.key)
    }
}
