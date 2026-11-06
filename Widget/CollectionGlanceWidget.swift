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
        .description("Your shelf at a glance: to do, in progress, done, and wishlist.")
        .supportedFamilies([.systemSmall, .systemMedium])
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
            if family == .systemSmall {
                smallBody
            } else {
                mediumBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(WidgetDeepLink.url(for: nil))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(snapshot.totalCount)")
                .font(.title.weight(.semibold))
                .monospacedDigit()
            Text(snapshot.totalCount == 1 ? "puzzle" : "puzzles")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(smallLine(snapshot.inProgressCount, singular: "in progress", plural: "in progress"))
                .font(.caption2)
            Text(smallLine(snapshot.todoCount, singular: "to do", plural: "to do"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var mediumBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("Collection")
                    .font(.headline)
                Spacer(minLength: 8)
                Text(totalLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .top, spacing: 8) {
                glanceStat("To do", snapshot.todoCount)
                glanceStat("In progress", snapshot.inProgressCount)
                glanceStat("Done", snapshot.completedCount)
                glanceStat("Wishlist", snapshot.wishlistCount)
            }
            if let extra = extraLine {
                Text(extra)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func glanceStat(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(value)")
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var totalLabel: String {
        let count = snapshot.totalCount
        return count == 1 ? "1 puzzle" : "\(count) puzzles"
    }

    private var extraLine: String? {
        var parts: [String] = []
        if snapshot.onLoanCount > 0 {
            parts.append(snapshot.onLoanCount == 1 ? "1 on loan" : "\(snapshot.onLoanCount) on loan")
        }
        if snapshot.abandonedCount > 0 {
            parts.append(snapshot.abandonedCount == 1 ? "1 abandoned" : "\(snapshot.abandonedCount) abandoned")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func smallLine(_ count: Int, singular: String, plural: String) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }

    private var accessibilityText: String {
        var parts = [
            totalLabel,
            "\(snapshot.todoCount) to do",
            "\(snapshot.inProgressCount) in progress",
            "\(snapshot.completedCount) done",
            "\(snapshot.wishlistCount) on the wishlist",
        ]
        if let extra = extraLine {
            parts.append(extra)
        }
        return parts.joined(separator: ". ")
    }
}
