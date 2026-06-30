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
    let totalSpend: Double?
    let spendCurrencyCode: String?
    let favoriteBrand: String?
    let averageDifficulty: Double?
    let averageInProgressPercent: Int?
    let replayedPuzzleCount: Int
    let averageHoursPer1000Pieces: Double?
    let paceBuckets: [PaceBucket]
    let purchaseLocationCounts: [PuzzleTagCount]
    let completionsByMonthThisYear: [Int]

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

        let spend = totalSpend(from: puzzles)

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
            topTags: PuzzleTagIndex.counts(from: puzzles, limit: 5),
            totalSpend: spend?.amount,
            spendCurrencyCode: spend?.currency,
            favoriteBrand: favoriteBrand(from: puzzles),
            averageDifficulty: averageDifficulty(from: puzzles),
            averageInProgressPercent: averageInProgressPercent(from: inProgress),
            replayedPuzzleCount: puzzles.filter { $0.timesCompleted >= 2 }.count,
            averageHoursPer1000Pieces: averageHoursPer1000Pieces(from: completed),
            paceBuckets: paceBuckets(from: completed),
            purchaseLocationCounts: purchaseLocationCounts(from: puzzles, limit: 3),
            completionsByMonthThisYear: completionsByMonth(
                in: completed,
                calendar: calendar,
                now: now
            )
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

    var formattedTotalSpend: String? {
        guard let totalSpend, totalSpend > 0 else { return nil }
        return PurchasePriceFormatting.displayLabel(price: totalSpend, currencyCode: spendCurrencyCode)
    }

    var formattedAverageDifficulty: String? {
        guard let averageDifficulty else { return nil }
        return String(format: "%.1f / 5", averageDifficulty)
    }

    var averageDifficultyDescriptor: String? {
        guard let averageDifficulty else { return nil }
        switch averageDifficulty {
        case ..<1.5: return "Mostly easygoing"
        case ..<2.5: return "Light challenge"
        case ..<3.5: return "Solid challenge"
        case ..<4.5: return "Tough puzzles"
        default: return "Expert level"
        }
    }

    var formattedAverageSpeed: String? {
        guard let averageHoursPer1000Pieces else { return nil }
        return PuzzleDetailMetrics(
            timeBucketLabel: nil,
            hoursPer1000Pieces: averageHoursPer1000Pieces
        ).formattedHoursPer1000Pieces
    }

    var formattedAverageInProgress: String? {
        guard let averageInProgressPercent else { return nil }
        return "\(averageInProgressPercent)%"
    }

    /// Busiest calendar month so far this year, e.g. ("March", 4). Nil when nothing finished this year.
    var mostProductiveMonthThisYear: (label: String, count: Int)? {
        guard let maxCount = completionsByMonthThisYear.max(), maxCount > 0,
              let index = completionsByMonthThisYear.firstIndex(of: maxCount) else { return nil }
        return (Self.monthSymbols[index], maxCount)
    }

    static let monthSymbols: [String] = {
        [
            "January",
            "February",
            "March",
            "April",
            "May",
            "June",
            "July",
            "August",
            "September",
            "October",
            "November",
            "December",
        ]
    }()

    static let monthAbbreviations: [String] = {
        ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    }()

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
        guard let time = puzzle.estimatedTimeSpent else { return 0 }
        let hours = max(time.hours ?? 0, 0)
        let minutes = max(time.minutes ?? 0, 0)
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
        purchaseLocationCounts(from: puzzles, limit: limit).map(\.name)
    }

    private static func purchaseLocationCounts(from puzzles: [Puzzle], limit: Int) -> [PuzzleTagCount] {
        let locations = puzzles
            .compactMap { $0.purchaseLocation?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !locations.isEmpty else { return [] }
        var frequencies: [String: (display: String, count: Int)] = [:]
        for location in locations {
            let key = location.lowercased()
            if let existing = frequencies[key] {
                frequencies[key] = (existing.display, existing.count + 1)
            } else {
                frequencies[key] = (location, 1)
            }
        }
        return frequencies.values
            .map { PuzzleTagCount(name: $0.display, count: $0.count) }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.count > rhs.count
            }
            .prefix(limit)
            .map { $0 }
    }

    private static func favoriteBrand(from puzzles: [Puzzle]) -> String? {
        let brands = puzzles
            .compactMap { $0.source?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !brands.isEmpty else { return nil }
        var frequencies: [String: (display: String, count: Int)] = [:]
        for brand in brands {
            let key = brand.lowercased()
            if let existing = frequencies[key] {
                frequencies[key] = (existing.display, existing.count + 1)
            } else {
                frequencies[key] = (brand, 1)
            }
        }
        return frequencies.values
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.display.localizedCaseInsensitiveCompare(rhs.display) == .orderedAscending
                }
                return lhs.count > rhs.count
            }
            .first?.display
    }

    private static func averageDifficulty(from puzzles: [Puzzle]) -> Double? {
        let values = puzzles.compactMap { puzzle -> Double? in
            guard puzzle.difficulty != .none, let raw = Double(puzzle.difficulty.rawValue) else { return nil }
            return raw
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func averageInProgressPercent(from inProgress: [Puzzle]) -> Int? {
        guard !inProgress.isEmpty else { return nil }
        let total = inProgress.reduce(0) { $0 + $1.progressPercent }
        return Int((Double(total) / Double(inProgress.count)).rounded())
    }

    private static func averageHoursPer1000Pieces(from completed: [Puzzle]) -> Double? {
        let speeds = completed.compactMap { puzzle -> Double? in
            guard let pieces = puzzle.pieces, pieces > 0 else { return nil }
            let minutes = minutesSpent(on: puzzle)
            guard minutes > 0 else { return nil }
            let hours = Double(minutes) / 60.0
            return hours / (Double(pieces) / 1000.0)
        }
        guard !speeds.isEmpty else { return nil }
        return speeds.reduce(0, +) / Double(speeds.count)
    }

    private static func paceBuckets(from completed: [Puzzle]) -> [PaceBucket] {
        let order = ["Quick finish", "Weekend puzzle", "Marathon project"]
        var counts: [String: Int] = [:]
        for puzzle in completed {
            let minutes = minutesSpent(on: puzzle)
            guard minutes > 0 else { continue }
            let label = PuzzleDetailMetrics.timeBucketLabel(forMinutes: minutes)
            counts[label, default: 0] += 1
        }
        return order.compactMap { label in
            guard let count = counts[label], count > 0 else { return nil }
            return PaceBucket(label: label, count: count)
        }
    }

    private static func totalSpend(from puzzles: [Puzzle]) -> (amount: Double, currency: String)? {
        let priced = puzzles.compactMap { puzzle -> (price: Double, code: String)? in
            guard let price = puzzle.purchasePrice, price > 0 else { return nil }
            let code = puzzle.purchaseCurrencyCode ?? Locale.current.currency?.identifier ?? "USD"
            return (price, code)
        }
        guard !priced.isEmpty else { return nil }
        let currencyFrequencies = Dictionary(grouping: priced, by: { $0.code }).mapValues(\.count)
        let dominant = currencyFrequencies
            .sorted { lhs, rhs in
                lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
            }
            .first?.key ?? "USD"
        let total = priced.filter { $0.code == dominant }.reduce(0.0) { $0 + $1.price }
        return (total, dominant)
    }

    private static func completionsByMonth(
        in completed: [Puzzle],
        calendar: Calendar,
        now: Date
    ) -> [Int] {
        var months = Array(repeating: 0, count: 12)
        let currentYear = calendar.component(.year, from: now)
        for puzzle in completed {
            let components = calendar.dateComponents([.year, .month], from: puzzle.completionDate)
            guard components.year == currentYear, let month = components.month,
                  (1...12).contains(month) else { continue }
            months[month - 1] += 1
        }
        return months
    }
}

// MARK: - PaceBucket

struct PaceBucket: Equatable, Identifiable {
    let label: String
    let count: Int

    var id: String { label }
}
