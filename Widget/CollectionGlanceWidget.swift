//
//  CollectionGlanceWidget.swift
//  Puzzle Buddy
//

import SwiftUI
import WidgetKit

struct CollectionGlanceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CollectionWidgetSnapshotStore.glanceKind, provider: CollectionGlanceProvider()) { entry in
            CollectionGlanceView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
        }
        .configurationDisplayName("Collection")
        .description("Shelf mix, finish and pace charts, and the stats you already track.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

struct CollectionGlanceEntry: TimelineEntry {
    let date: Date
    let snapshot: CollectionWidgetSnapshot
}

struct CollectionGlanceProvider: TimelineProvider {
    func placeholder(in context: Context) -> CollectionGlanceEntry {
        CollectionGlanceEntry(date: Date(), snapshot: .glancePlaceholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CollectionGlanceEntry) -> Void) {
        if context.isPreview, CollectionWidgetSnapshotStore.load() == nil {
            completion(CollectionGlanceEntry(date: Date(), snapshot: .glancePlaceholder))
            return
        }
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CollectionGlanceEntry>) -> Void) {
        let entry = currentEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: entry.date)
            ?? entry.date.addingTimeInterval(6 * 60 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> CollectionGlanceEntry {
        let snapshot = CollectionWidgetSnapshotStore.load() ?? .empty
        return CollectionGlanceEntry(date: Date(), snapshot: snapshot)
    }
}

struct CollectionGlanceView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CollectionGlanceEntry

    private var snapshot: CollectionWidgetSnapshot { entry.snapshot }

    var body: some View {
        Group {
            if snapshot.totalCount == 0 {
                emptyBody
            } else if family == .systemSmall {
                smallBody
            } else if family == .systemLarge || family == .systemExtraLarge {
                largeBody
            } else {
                mediumBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(WidgetDeepLink.statsURL)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var emptyBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No puzzles yet")
                .font(.headline)
            Text("Add one in Puzzle Buddy to see your shelf.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(snapshot.totalCount)")
                .font(.title.weight(.semibold))
                .monospacedDigit()
                .widgetAccentable()
            Text(snapshot.totalCount == 1 ? "puzzle" : "puzzles")
                .font(.caption)
                .foregroundStyle(.secondary)
            WidgetShareBar(segments: WidgetShelf.segments(for: snapshot))
            Spacer(minLength: 0)
            Text(smallLine(snapshot.inProgressCount, singular: "in progress", plural: "in progress"))
                .font(.caption2)
            Text(smallLine(snapshot.todoCount, singular: "to do", plural: "to do"))
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let insight = snapshot.insightLines.first {
                Text(insight)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var mediumBody: some View {
        ViewThatFits(in: .vertical) {
            mediumStack(showsInsights: true, showsFootnote: true)
            mediumStack(showsInsights: false, showsFootnote: true)
            mediumStack(showsInsights: false, showsFootnote: false)
        }
    }

    private func mediumStack(showsInsights: Bool, showsFootnote: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            collectionHeader
            WidgetShareBar(segments: WidgetShelf.segments(for: snapshot))
            shelfCounts
            if showsInsights {
                insightLines(limit: 2)
            }
            if showsFootnote, let footnote = snapshot.glanceFootnote {
                Text(footnote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    private var largeBody: some View {
        ViewThatFits(in: .vertical) {
            largeStack(showsChart: true, showsPace: true, showsActivity: true, showsInsights: true)
            largeStack(showsChart: true, showsPace: true, showsActivity: true, showsInsights: false)
            largeStack(showsChart: true, showsPace: false, showsActivity: true, showsInsights: true)
            largeStack(showsChart: true, showsPace: false, showsActivity: true, showsInsights: false)
            largeStack(showsChart: false, showsPace: true, showsActivity: true, showsInsights: true)
        }
    }

    private func largeStack(
        showsChart: Bool,
        showsPace: Bool,
        showsActivity: Bool,
        showsInsights: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            collectionHeader
            WidgetShareBar(segments: WidgetShelf.segments(for: snapshot))
            shelfCounts
            if showsChart, snapshot.showsYearChart {
                WidgetMonthChart(
                    months: snapshot.completionsByMonth,
                    year: snapshot.activityYear,
                    currentMonthIndex: snapshot.currentMonthIndex
                )
            }
            if showsPace, snapshot.showsPaceChart {
                WidgetPaceChart(labels: snapshot.paceLabels, counts: snapshot.paceCounts)
            }
            if showsInsights {
                insightLines(limit: 4)
            }
            if showsActivity, snapshot.activityYear > 0 {
                activityCounts
            }
            if let extra = snapshot.shelfExtraLine {
                Text(extra)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func insightLines(limit: Int) -> some View {
        let lines = Array(snapshot.insightLines.prefix(limit))
        if !lines.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
    }

    private var collectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Collection")
                .font(.headline)
            Spacer(minLength: 8)
            Text(totalLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var shelfCounts: some View {
        HStack(alignment: .top, spacing: 8) {
            glanceStat("To do", snapshot.todoCount, tint: WidgetPalette.todo)
            glanceStat("In progress", snapshot.inProgressCount, tint: WidgetPalette.inProgress)
            glanceStat("Done", snapshot.completedCount, tint: WidgetPalette.done)
            glanceStat("Wishlist", snapshot.wishlistCount, tint: WidgetPalette.wishlist)
        }
    }

    private var activityCounts: some View {
        HStack(alignment: .top, spacing: 8) {
            activityStat("This month", "\(snapshot.completionsThisMonth)")
            activityStat("This year", "\(snapshot.completionsThisYear)")
            activityStat("Pieces", snapshot.totalPiecesCompleted.formatted(.number))
            activityStat("Time", snapshot.puzzlingTimeLabel)
        }
    }

    private func glanceStat(_ title: String, _ value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(value)")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .widgetAccentable()
            HStack(spacing: 3) {
                Circle()
                    .fill(tint)
                    .frame(width: 5, height: 5)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activityStat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var totalLabel: String {
        let count = snapshot.totalCount
        return count == 1 ? "1 puzzle" : "\(count) puzzles"
    }

    private func smallLine(_ count: Int, singular: String, plural: String) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }

    private var accessibilityText: String {
        if snapshot.totalCount == 0 {
            return "No puzzles yet. Add one in Puzzle Buddy to see your shelf."
        }
        var parts = [
            totalLabel,
            "\(snapshot.todoCount) to do",
            "\(snapshot.inProgressCount) in progress",
            "\(snapshot.completedCount) done",
            "\(snapshot.wishlistCount) on the wishlist",
        ]
        if let footnote = snapshot.glanceFootnote {
            parts.append(footnote)
        }
        if !snapshot.insightLines.isEmpty {
            parts.append(snapshot.insightLines.joined(separator: ". "))
        }
        if family == .systemLarge || family == .systemExtraLarge {
            if let chart = snapshot.yearChartSpokenSummary {
                parts.append(chart)
            }
            if let pace = snapshot.paceSpokenSummary {
                parts.append(pace)
            }
        }
        return parts.joined(separator: ". ")
    }
}
