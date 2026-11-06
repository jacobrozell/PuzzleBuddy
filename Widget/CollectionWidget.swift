//
//  CollectionWidget.swift
//  Puzzle Buddy
//

import SwiftUI
import WidgetKit

@main
struct PuzzleBuddyWidgetBundle: WidgetBundle {
    var body: some Widget {
        CollectionWidget()
        CollectionGlanceWidget()
    }
}

struct CollectionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CollectionWidgetSnapshotStore.kind, provider: CollectionWidgetProvider()) { entry in
            CollectionWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
        }
        .configurationDisplayName("On the table")
        .description("The puzzle you’re working on, and how many are still to do.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CollectionWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: CollectionWidgetSnapshot
}

struct CollectionWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CollectionWidgetEntry {
        CollectionWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (CollectionWidgetEntry) -> Void) {
        if context.isPreview, CollectionWidgetSnapshotStore.load() == nil {
            completion(CollectionWidgetEntry(date: Date(), snapshot: .placeholder))
            return
        }
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CollectionWidgetEntry>) -> Void) {
        let snapshot = CollectionWidgetSnapshotStore.load() ?? .empty
        let now = Date()
        let dates = snapshot.tableTimelineDates(from: now)
        let entries = dates.map { CollectionWidgetEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .after(snapshot.tableTimelineRefresh(after: dates, now: now))))
    }

    private func currentEntry() -> CollectionWidgetEntry {
        let snapshot = CollectionWidgetSnapshotStore.load() ?? .empty
        return CollectionWidgetEntry(date: Date(), snapshot: snapshot)
    }
}

struct CollectionWidgetView: View {
    let entry: CollectionWidgetEntry

    var body: some View {
        ViewThatFits(in: .vertical) {
            content(showsDetail: true, showsStatus: true, titleLines: 2, footerLines: 2)
            content(showsDetail: true, showsStatus: true, titleLines: 2, footerLines: 1)
            content(showsDetail: false, showsStatus: true, titleLines: 2, footerLines: 1)
            content(showsDetail: true, showsStatus: false, titleLines: 1, footerLines: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(WidgetDeepLink.url(for: entry.snapshot.featuredPuzzleID))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func content(showsDetail: Bool, showsStatus: Bool, titleLines: Int, footerLines: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.snapshot.featuredTitle != nil || entry.snapshot.inProgressCount > 0 {
                Text(entry.snapshot.featuredTitle ?? "In progress")
                    .font(.headline)
                    .lineLimit(titleLines)
                if showsDetail, let detail = entry.snapshot.featuredDetail {
                    Text(detail)
                        .font(.subheadline)
                        .lineLimit(1)
                }
                if showsStatus {
                    statusLine
                }
            } else {
                Text("Nothing on the table")
                    .font(.headline)
                    .lineLimit(titleLines)
            }
            Spacer(minLength: 0)
            Text(entry.snapshot.tableFooter)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(footerLines)
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        if entry.snapshot.showsLiveTimer(at: entry.date), let anchor = entry.snapshot.liveTimerAnchor {
            HStack(spacing: 4) {
                Text("Timer on ·")
                Text(anchor, style: .timer)
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        } else if let status = entry.snapshot.featuredStatusLine(at: entry.date) {
            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var accessibilityText: String {
        var parts: [String] = []
        if let title = entry.snapshot.featuredTitle {
            parts.append(title)
        } else if entry.snapshot.inProgressCount == 0 {
            parts.append("Nothing on the table")
        } else {
            parts.append("In progress")
        }
        if let detail = entry.snapshot.featuredDetail {
            parts.append(detail)
        }
        if let status = entry.snapshot.featuredStatusLine(at: entry.date) {
            parts.append(status)
        }
        parts.append(entry.snapshot.tableFooter)
        return parts.joined(separator: ". ")
    }
}
