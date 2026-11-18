//
//  WidgetCharts.swift
//  Puzzle Buddy
//

import SwiftUI

enum WidgetPalette {
    static let todo = Color(red: 0.36, green: 0.56, blue: 0.70)
    static let inProgress = Color(red: 0.05, green: 0.55, blue: 0.62)
    static let done = Color(red: 0.93, green: 0.45, blue: 0.13)
    static let wishlist = Color(red: 0.49, green: 0.38, blue: 0.82)
    static let abandoned = Color(red: 0.55, green: 0.55, blue: 0.58)
}

struct WidgetShareSegment: Identifiable {
    let id: String
    let fraction: Double
    let color: Color
}

enum WidgetShelf {
    static func segments(for snapshot: CollectionWidgetSnapshot) -> [WidgetShareSegment] {
        let total = Double(snapshot.totalCount)
        guard total > 0 else { return [] }
        let rows: [(String, Int, Color)] = [
            ("todo", snapshot.todoCount, WidgetPalette.todo),
            ("inProgress", snapshot.inProgressCount, WidgetPalette.inProgress),
            ("done", snapshot.completedCount, WidgetPalette.done),
            ("wishlist", snapshot.wishlistCount, WidgetPalette.wishlist),
            ("abandoned", snapshot.abandonedCount, WidgetPalette.abandoned),
        ]
        return rows.compactMap { id, count, color in
            guard count > 0 else { return nil }
            return WidgetShareSegment(id: id, fraction: Double(count) / total, color: color)
        }
    }
}

struct WidgetProgressBar: View {
    let percent: Int

    var body: some View {
        let fraction = min(max(Double(percent), 0), 100) / 100
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.12))
                Capsule()
                    .fill(WidgetPalette.inProgress)
                    .frame(width: proxy.size.width * fraction)
                    .widgetAccentable()
            }
        }
        .frame(height: 6)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

struct WidgetShareBar: View {
    let segments: [WidgetShareSegment]

    var body: some View {
        GeometryReader { proxy in
            let visible = segments.filter { $0.fraction > 0 }
            if visible.isEmpty {
                Capsule()
                    .fill(Color.primary.opacity(0.12))
            } else {
                shareBar(visible, width: proxy.size.width)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private func shareBar(_ visible: [WidgetShareSegment], width: CGFloat) -> some View {
        let gap: CGFloat = 2
        let gaps = gap * CGFloat(max(visible.count - 1, 0))
        let usable = max(width - gaps, 1)
        let weights = visible.map { max($0.fraction, 0.035) }
        let weightSum = max(weights.reduce(0, +), 0.01)
        return HStack(spacing: gap) {
            ForEach(Array(visible.enumerated()), id: \.element.id) { index, segment in
                Capsule()
                    .fill(segment.color)
                    .frame(width: usable * CGFloat(weights[index] / weightSum))
            }
        }
    }
}

struct WidgetMonthChart: View {
    let months: [Int]
    let year: Int
    let currentMonthIndex: Int

    private var maxCount: Int { max(months.max() ?? 0, 1) }
    private var total: Int { months.reduce(0, +) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<12, id: \.self) { index in
                    bar(index: index)
                }
            }
            .frame(height: 52)
            HStack(spacing: 3) {
                ForEach(0..<12, id: \.self) { index in
                    Text(CollectionWidgetSnapshot.monthAbbreviations[index])
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(index == currentMonthIndex ? WidgetPalette.inProgress : .secondary)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var title: String {
        if total == 0 { return "No finishes in \(year)" }
        let noun = total == 1 ? "finish" : "finishes"
        return "\(total) \(noun) in \(year)"
    }

    private func bar(index: Int) -> some View {
        let count = index < months.count ? months[index] : 0
        let fraction = CGFloat(count) / CGFloat(maxCount)
        let isCurrent = index == currentMonthIndex
        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(fill(count: count, isCurrent: isCurrent))
                .frame(height: count == 0 ? 4 : max(6, fraction * 48))
                .widgetAccentable(count > 0 && isCurrent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func fill(count: Int, isCurrent: Bool) -> Color {
        if count == 0 { return Color.primary.opacity(0.12) }
        return isCurrent ? WidgetPalette.done : WidgetPalette.inProgress
    }
}

struct WidgetPaceChart: View {
    let labels: [String]
    let counts: [Int]

    private var rows: [(String, Int)] {
        Array(zip(labels, counts)).filter { $0.1 > 0 }
    }

    private var maxCount: Int { max(rows.map(\.1).max() ?? 1, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Pace")
                .font(.caption.weight(.medium))
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                paceRow(label: row.0, count: row.1)
            }
        }
        .accessibilityHidden(true)
    }

    private func paceRow(label: String, count: Int) -> some View {
        let fraction = CGFloat(count) / CGFloat(maxCount)
        return HStack(spacing: 6) {
            Text(label)
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 96, alignment: .leading)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.12))
                    Capsule()
                        .fill(WidgetPalette.done)
                        .frame(width: proxy.size.width * fraction)
                }
            }
            .frame(height: 6)
            Text("\(count)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
