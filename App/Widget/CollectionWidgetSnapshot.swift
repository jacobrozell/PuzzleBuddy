//
//  CollectionWidgetSnapshot.swift
//  Puzzle Buddy
//
//  Shared by the app and the home screen widgets.
//

import Foundation

struct CollectionWidgetSnapshot: Codable, Equatable {
    var inProgressCount: Int
    var todoCount: Int
    var completedCount: Int = 0
    var wishlistCount: Int = 0
    var abandonedCount: Int = 0
    var onLoanCount: Int = 0
    /// 0...100 for the puzzle on the table. The widget draws this as a bar.
    var featuredProgressPercent: Int = 0
    var completionsThisMonth: Int = 0
    var completionsThisYear: Int = 0
    /// Twelve counts, January through December, for the activity chart.
    var completionsByMonth: [Int] = []
    var activityYear: Int = 0
    /// 0-based month index for highlighting the current bar.
    var currentMonthIndex: Int = 0
    var totalPiecesCompleted: Int = 0
    var totalMinutesPuzzling: Int = 0
    /// Short facts from the Stats tab, most useful first.
    var insightLines: [String] = []
    var paceLabels: [String] = []
    var paceCounts: [Int] = []
    /// True when the featured puzzle is a to-do, because nothing is in progress.
    var featuredIsBacklog: Bool = false
    var featuredPuzzleID: UUID? = nil
    var featuredTitle: String? = nil
    var featuredDetail: String? = nil
    var featuredStatus: String? = nil
    /// Start of the featured puzzle. The widget turns this into “days on the table” at each midnight.
    var featuredStartDate: Date? = nil
    var featuredTimerAccumulatedSeconds: Int = 0
    /// Set only while the timer is running. The widget counts from this anchor instead of a frozen label.
    var featuredTimerRunningSince: Date? = nil
    var updatedAt: Date

    static let empty = CollectionWidgetSnapshot(
        inProgressCount: 0,
        todoCount: 0,
        featuredPuzzleID: nil,
        featuredTitle: nil,
        featuredDetail: nil,
        featuredStatus: nil,
        updatedAt: .distantPast
    )

    var totalCount: Int {
        inProgressCount + todoCount + completedCount + wishlistCount + abandonedCount
    }

    static let placeholder = CollectionWidgetSnapshot(
        inProgressCount: 1,
        todoCount: 3,
        featuredProgressPercent: 40,
        featuredPuzzleID: nil,
        featuredTitle: "Coastal Town",
        featuredDetail: "1,000 pieces · 40%",
        featuredStatus: "Timer on · 25m",
        updatedAt: Date()
    )

    static var glancePlaceholder: CollectionWidgetSnapshot {
        let calendar = Calendar.current
        let now = Date()
        let month = max(calendar.component(.month, from: now) - 1, 0)
        var months = Array(repeating: 0, count: 12)
        months[month] = 2
        if month >= 1 { months[month - 1] = 1 }
        if month >= 3 { months[month - 3] = 3 }
        return CollectionWidgetSnapshot(
            inProgressCount: 2,
            todoCount: 4,
            completedCount: 18,
            wishlistCount: 3,
            abandonedCount: 1,
            onLoanCount: 1,
            completionsThisMonth: 2,
            completionsThisYear: months.reduce(0, +),
            completionsByMonth: months,
            activityYear: calendar.component(.year, from: now),
            currentMonthIndex: month,
            totalPiecesCompleted: 18_400,
            totalMinutesPuzzling: 21 * 60,
            insightLines: ["40% along", "4.5 avg rating", "About 2 weeks to finish"],
            paceLabels: ["Quick finish", "Weekend puzzle", "Marathon project"],
            paceCounts: [6, 9, 3],
            updatedAt: now
        )
    }

    /// Footer under the featured puzzle. The headline already accounts for one in-progress puzzle,
    /// including the untitled “In progress” headline.
    var tableFooter: String {
        if featuredIsBacklog {
            let remaining = max(todoCount - 1, 0)
            if remaining == 1 { return "1 more to do" }
            if remaining > 1 { return "\(remaining) more to do" }
            return "Ready to start"
        }
        var parts: [String] = []
        let showingFeatured = featuredTitle != nil || inProgressCount > 0
        let featuredSlots = showingFeatured && inProgressCount > 0 ? 1 : 0
        let extra = inProgressCount - featuredSlots
        if extra > 0 {
            parts.append(extra == 1 ? "1 more in progress" : "\(extra) more in progress")
        }
        if todoCount > 0 {
            let count = todoCount
            parts.append(count == 1 ? "1 to do" : "\(count) to do")
        }
        if parts.isEmpty {
            return inProgressCount == 0 ? "To-do is clear" : "On the table"
        }
        return parts.joined(separator: " · ")
    }

    /// Month, pieces, time, and the counts that don’t fit the four shelf numbers.
    var glanceFootnote: String? {
        let parts = glanceFootnoteParts
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// On loan and abandoned, for the large widget that already shows the other stats.
    var shelfExtraLine: String? {
        var parts: [String] = []
        if onLoanCount > 0 {
            parts.append(onLoanCount == 1 ? "1 on loan" : "\(onLoanCount) on loan")
        }
        if abandonedCount > 0 {
            parts.append(abandonedCount == 1 ? "1 abandoned" : "\(abandonedCount) abandoned")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var showsYearChart: Bool {
        activityYear > 0 && completionsByMonth.count == 12
    }

    var showsPaceChart: Bool {
        !paceLabels.isEmpty && paceLabels.count == paceCounts.count && paceCounts.contains { $0 > 0 }
    }

    var paceSpokenSummary: String? {
        guard showsPaceChart else { return nil }
        let rows = zip(paceLabels, paceCounts)
            .filter { $0.1 > 0 }
            .map { "\($0.0): \($0.1)." }
        return (["Your pace."] + rows).joined(separator: " ")
    }

    var yearChartSpokenSummary: String? {
        guard showsYearChart else { return nil }
        let total = completionsByMonth.reduce(0, +)
        guard total > 0 else { return "No puzzles finished in \(activityYear)." }
        let months = zip(Self.monthNames, completionsByMonth)
            .filter { $0.1 > 0 }
            .map { "\($0.0): \($0.1)." }
        return (["\(total) finished in \(activityYear)."] + months).joined(separator: " ")
    }

    var puzzlingTimeLabel: String {
        Self.puzzlingTimeLabel(minutes: totalMinutesPuzzling)
    }

    static func puzzlingTimeLabel(minutes: Int) -> String {
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

    static let monthNames = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    static let monthAbbreviations = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ]

    private var glanceFootnoteParts: [String] {
        var parts: [String] = []
        if completionsThisMonth > 0 {
            let line = completionsThisMonth == 1 ? "1 finished this month" : "\(completionsThisMonth) finished this month"
            parts.append(line)
        }
        if totalPiecesCompleted > 0 {
            parts.append("\(totalPiecesCompleted.formatted(.number)) pieces")
        }
        if totalMinutesPuzzling > 0 {
            parts.append(puzzlingTimeLabel)
        }
        if let extra = shelfExtraLine {
            parts.append(extra)
        }
        return parts
    }

    func showsLiveTimer(at now: Date) -> Bool {
        guard let runningSince = featuredTimerRunningSince else { return false }
        return now >= runningSince
    }

    /// Anchor for `Text(_:style: .timer)`. Includes time accumulated before this run.
    var liveTimerAnchor: Date? {
        guard let runningSince = featuredTimerRunningSince else { return nil }
        let accumulated = TimeInterval(max(featuredTimerAccumulatedSeconds, 0))
        return runningSince.addingTimeInterval(-accumulated)
    }

    func featuredStatusLine(at now: Date, calendar: Calendar = .current) -> String? {
        if let line = timerStatusLine(at: now) {
            return line
        }
        if let line = daysOnTableLine(at: now, calendar: calendar) {
            return line
        }
        return featuredStatus
    }

    /// One entry per midnight while a puzzle is on the table and the timer is stopped,
    /// so the day count moves without opening the app. A running timer uses one entry;
    /// the label itself ticks.
    func tableTimelineDates(from now: Date, calendar: Calendar = .current, horizonDays: Int = 7) -> [Date] {
        if showsLiveTimer(at: now) {
            return [now]
        }
        guard featuredStartDate != nil else { return [now] }
        var dates = [now]
        var day = calendar.startOfDay(for: now)
        for _ in 0..<horizonDays {
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            if next > now {
                dates.append(next)
            }
            day = next
        }
        return dates
    }

    func tableTimelineRefresh(after dates: [Date], now: Date, calendar: Calendar = .current) -> Date {
        if let last = dates.last, last > now {
            return last.addingTimeInterval(60)
        }
        return calendar.date(byAdding: .hour, value: 6, to: now) ?? now.addingTimeInterval(6 * 60 * 60)
    }

    private func timerStatusLine(at now: Date) -> String? {
        guard showsLiveTimer(at: now), let runningSince = featuredTimerRunningSince else { return nil }
        let elapsed = max(featuredTimerAccumulatedSeconds, 0) + Int(now.timeIntervalSince(runningSince))
        return "Timer on · \(Self.elapsedLabel(elapsed))"
    }

    private func daysOnTableLine(at now: Date, calendar: Calendar) -> String? {
        guard featuredTimerRunningSince == nil, let start = featuredStartDate else { return nil }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: start),
            to: calendar.startOfDay(for: now)
        ).day ?? 0
        if days <= 0 { return "Started today" }
        if days == 1 { return "1 day on the table" }
        return "\(days) days on the table"
    }

    static func elapsedLabel(_ seconds: Int) -> String {
        let safe = max(0, seconds)
        let hours = safe / 3600
        let minutes = (safe % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "just started"
    }
}

extension CollectionWidgetSnapshot {
    private enum CodingKeys: String, CodingKey {
        case inProgressCount
        case todoCount
        case completedCount
        case wishlistCount
        case abandonedCount
        case onLoanCount
        case featuredProgressPercent
        case completionsThisMonth
        case completionsThisYear
        case completionsByMonth
        case activityYear
        case currentMonthIndex
        case totalPiecesCompleted
        case totalMinutesPuzzling
        case insightLines
        case paceLabels
        case paceCounts
        case featuredIsBacklog
        case featuredPuzzleID
        case featuredTitle
        case featuredDetail
        case featuredStatus
        case featuredStartDate
        case featuredTimerAccumulatedSeconds
        case featuredTimerRunningSince
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inProgressCount = try container.decode(Int.self, forKey: .inProgressCount)
        todoCount = try container.decode(Int.self, forKey: .todoCount)
        completedCount = try container.decodeIfPresent(Int.self, forKey: .completedCount) ?? 0
        wishlistCount = try container.decodeIfPresent(Int.self, forKey: .wishlistCount) ?? 0
        abandonedCount = try container.decodeIfPresent(Int.self, forKey: .abandonedCount) ?? 0
        onLoanCount = try container.decodeIfPresent(Int.self, forKey: .onLoanCount) ?? 0
        featuredProgressPercent = try container.decodeIfPresent(Int.self, forKey: .featuredProgressPercent) ?? 0
        completionsThisMonth = try container.decodeIfPresent(Int.self, forKey: .completionsThisMonth) ?? 0
        completionsThisYear = try container.decodeIfPresent(Int.self, forKey: .completionsThisYear) ?? 0
        completionsByMonth = try container.decodeIfPresent([Int].self, forKey: .completionsByMonth) ?? []
        activityYear = try container.decodeIfPresent(Int.self, forKey: .activityYear) ?? 0
        currentMonthIndex = try container.decodeIfPresent(Int.self, forKey: .currentMonthIndex) ?? 0
        totalPiecesCompleted = try container.decodeIfPresent(Int.self, forKey: .totalPiecesCompleted) ?? 0
        totalMinutesPuzzling = try container.decodeIfPresent(Int.self, forKey: .totalMinutesPuzzling) ?? 0
        insightLines = try container.decodeIfPresent([String].self, forKey: .insightLines) ?? []
        paceLabels = try container.decodeIfPresent([String].self, forKey: .paceLabels) ?? []
        paceCounts = try container.decodeIfPresent([Int].self, forKey: .paceCounts) ?? []
        featuredIsBacklog = try container.decodeIfPresent(Bool.self, forKey: .featuredIsBacklog) ?? false
        featuredPuzzleID = try container.decodeIfPresent(UUID.self, forKey: .featuredPuzzleID)
        featuredTitle = try container.decodeIfPresent(String.self, forKey: .featuredTitle)
        featuredDetail = try container.decodeIfPresent(String.self, forKey: .featuredDetail)
        featuredStatus = try container.decodeIfPresent(String.self, forKey: .featuredStatus)
        featuredStartDate = try container.decodeIfPresent(Date.self, forKey: .featuredStartDate)
        featuredTimerAccumulatedSeconds = try container.decodeIfPresent(Int.self, forKey: .featuredTimerAccumulatedSeconds) ?? 0
        featuredTimerRunningSince = try container.decodeIfPresent(Date.self, forKey: .featuredTimerRunningSince)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(inProgressCount, forKey: .inProgressCount)
        try container.encode(todoCount, forKey: .todoCount)
        try container.encode(completedCount, forKey: .completedCount)
        try container.encode(wishlistCount, forKey: .wishlistCount)
        try container.encode(abandonedCount, forKey: .abandonedCount)
        try container.encode(onLoanCount, forKey: .onLoanCount)
        try container.encode(featuredProgressPercent, forKey: .featuredProgressPercent)
        try container.encode(completionsThisMonth, forKey: .completionsThisMonth)
        try container.encode(completionsThisYear, forKey: .completionsThisYear)
        try container.encode(completionsByMonth, forKey: .completionsByMonth)
        try container.encode(activityYear, forKey: .activityYear)
        try container.encode(currentMonthIndex, forKey: .currentMonthIndex)
        try container.encode(totalPiecesCompleted, forKey: .totalPiecesCompleted)
        try container.encode(totalMinutesPuzzling, forKey: .totalMinutesPuzzling)
        try container.encode(insightLines, forKey: .insightLines)
        try container.encode(paceLabels, forKey: .paceLabels)
        try container.encode(paceCounts, forKey: .paceCounts)
        try container.encode(featuredIsBacklog, forKey: .featuredIsBacklog)
        try container.encodeIfPresent(featuredPuzzleID, forKey: .featuredPuzzleID)
        try container.encodeIfPresent(featuredTitle, forKey: .featuredTitle)
        try container.encodeIfPresent(featuredDetail, forKey: .featuredDetail)
        try container.encodeIfPresent(featuredStatus, forKey: .featuredStatus)
        try container.encodeIfPresent(featuredStartDate, forKey: .featuredStartDate)
        try container.encode(featuredTimerAccumulatedSeconds, forKey: .featuredTimerAccumulatedSeconds)
        try container.encodeIfPresent(featuredTimerRunningSince, forKey: .featuredTimerRunningSince)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

enum WidgetDeepLink {
    static let pendingPuzzleIDKey = "widgetPendingPuzzleID"
    static let pendingDestinationKey = "widgetPendingDestination"
    static let destinationStats = "stats"
    static let destinationPuzzles = "puzzles"
    static let statsURL = URL(string: "puzzlebuddy://stats")!

    static func url(for puzzleID: UUID?) -> URL {
        guard let puzzleID else {
            return URL(string: "puzzlebuddy://collection")!
        }
        return URL(string: "puzzlebuddy://puzzle/\(puzzleID.uuidString)")!
    }

    /// Accepts only `puzzlebuddy://puzzle/<uuid>`. Anything else is ignored.
    static func puzzleID(from url: URL) -> UUID? {
        guard url.scheme == "puzzlebuddy", url.host == "puzzle" else { return nil }
        let raw = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return UUID(uuidString: raw)
    }

    static func remember(_ url: URL, defaults: UserDefaults = .standard) {
        if let id = puzzleID(from: url) {
            defaults.set(id.uuidString, forKey: pendingPuzzleIDKey)
            defaults.removeObject(forKey: pendingDestinationKey)
            return
        }
        guard url.scheme == "puzzlebuddy" else { return }
        switch url.host {
        case destinationStats:
            defaults.set(destinationStats, forKey: pendingDestinationKey)
            defaults.removeObject(forKey: pendingPuzzleIDKey)
        case "collection":
            defaults.set(destinationPuzzles, forKey: pendingDestinationKey)
            defaults.removeObject(forKey: pendingPuzzleIDKey)
        default:
            break
        }
    }
}

enum CollectionWidgetSnapshotStore {
    static let appGroupID = "group.com.jacobrozell.Puzzle-Buddy"
    static let kind = "CollectionWidget"
    static let glanceKind = "CollectionGlanceWidget"
    static let defaultsKey = "collectionWidgetSnapshot"
    static let openURL = URL(string: "puzzlebuddy://collection")!

    static func publish(_ snapshot: CollectionWidgetSnapshot, defaults: UserDefaults? = nil) {
        guard let store = defaults ?? UserDefaults(suiteName: appGroupID) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        store.set(data, forKey: defaultsKey)
    }

    static func load(defaults: UserDefaults? = nil) -> CollectionWidgetSnapshot? {
        let store = defaults ?? UserDefaults(suiteName: appGroupID)
        guard let data = store?.data(forKey: defaultsKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CollectionWidgetSnapshot.self, from: data)
    }
}
