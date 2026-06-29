//
//  CollectionStatsView.swift
//  Puzzle Buddy
//

import SwiftUI

// MARK: - CollectionStatsView

struct CollectionStatsView: View {
    @ObservedObject var ps: PuzzleStore
    @State private var showPickNext = false
    @State private var pendingMilestone: CollectionMilestone?

    private var stats: CollectionStats {
        CollectionStats.compute(from: ps.puzzles)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s5) {
                if ps.puzzles.isEmpty {
                    welcomeHeader
                    emptyState
                } else {
                    if let pendingMilestone {
                        milestoneBanner(pendingMilestone)
                    }
                    heroSection
                    if !highlights.isEmpty {
                        highlightStrip
                    }
                    if stats.completedCount > 0 {
                        yearActivitySection
                    }
                    collectionSection
                    if hasHowYouPuzzleContent {
                        howYouPuzzleSection
                    }
                    if !stats.paceBuckets.isEmpty {
                        paceSection
                    }
                    if stats.biggestCompletedPieces != nil || stats.smallestCompletedPieces != nil {
                        pieceRangeSection
                    }
                    if !stats.purchaseLocationCounts.isEmpty {
                        shopSection
                    }
                    if !stats.topTags.isEmpty {
                        topTagsSection
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.vertical, DS.Spacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier(A11yID.collectionStatsScreen)
            .accessibilityElement(children: .contain)
        }
        .readableBrandScreenChrome()
        .onAppear {
            refreshPendingMilestone()
        }
        .onChange(of: ps.puzzles.count) { _, _ in
            refreshPendingMilestone()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if ProductService.isPickNextEnabled {
                    Button {
                        showPickNext = true
                    } label: {
                        Image(systemName: "dice")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Pick my next puzzle")
                    .accessibilityIdentifier(A11yID.collectionStatsPickNextButton)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                PuzzleShareMenu(
                    entireCollection: ps.puzzles,
                    visibleList: ps.puzzles
                )
            }
        }
        .sheet(isPresented: $showPickNext) {
            PickNextPuzzleView(ps: ps, entryPoint: "stats")
        }
    }

    private func refreshPendingMilestone() {
        let acknowledged = CollectionMilestones.loadAcknowledged()
        pendingMilestone = CollectionMilestones.newlyEarned(
            stats: stats,
            previouslyAcknowledged: acknowledged
        ).first
    }

    private func milestoneBanner(_ milestone: CollectionMilestone) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            HStack(spacing: DS.Spacing.s3) {
                Image(systemName: milestone.icon)
                    .font(.title2)
                    .foregroundStyle(Brand.accentWarm)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text(milestone.title)
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)
                    if let subtitle = milestone.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Brand.textSecondary)
                    }
                }
            }
            Button("Nice!") {
                CollectionMilestones.acknowledge(milestone.id)
                pendingMilestone = nil
            }
            .buttonStyle(BrandSecondaryButtonStyle())
            .accessibilityIdentifier(A11yID.collectionStatsMilestoneDismiss)
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.cardElevated)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(A11yID.collectionStatsMilestoneBanner)
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text("Your collection at a glance")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Brand.textPrimary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: DS.Spacing.s3) {
                heroCard(
                    value: "\(stats.completedCount)",
                    label: "Puzzles completed",
                    icon: "checkmark.circle.fill",
                    identifier: A11yID.collectionStatsCompletedCard
                )
                heroCard(
                    value: CollectionStats.formatPieceCount(stats.totalPiecesCompleted),
                    label: "Pieces assembled",
                    icon: "puzzlepiece.extension.fill",
                    identifier: A11yID.collectionStatsPiecesCard
                )
            }
        }
    }

    private var highlights: [StatHighlight] {
        var result: [StatHighlight] = [
            StatHighlight(
                icon: "calendar",
                value: "\(stats.completionsThisYear)",
                caption: "This year"
            )
        ]
        if stats.totalMinutesPuzzling > 0 {
            result.append(
                StatHighlight(
                    icon: "clock.fill",
                    value: stats.formattedTotalHours,
                    caption: "At the table"
                )
            )
        }
        if let rating = stats.formattedAverageRating {
            result.append(
                StatHighlight(
                    icon: "star.fill",
                    value: rating,
                    caption: "Avg. rating"
                )
            )
        }
        if stats.inProgressCount > 0 {
            result.append(
                StatHighlight(
                    icon: "hourglass",
                    value: "\(stats.inProgressCount)",
                    caption: "On the table"
                )
            )
        }
        if let spend = stats.formattedTotalSpend {
            result.append(
                StatHighlight(
                    icon: "bag.fill",
                    value: spend,
                    caption: "Collection value"
                )
            )
        }
        return result
    }

    private var highlightStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.s3) {
                ForEach(highlights) { highlight in
                    HighlightChip(highlight: highlight)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .accessibilityIdentifier(A11yID.collectionStatsHighlightStrip)
        .accessibilityElement(children: .contain)
    }

    private var collectionSection: some View {
        statsSection(title: "Collection") {
            statCard(
                value: "\(stats.totalCount)",
                label: "Total collection",
                subtitle: "Puzzles you own",
                identifier: A11yID.collectionStatsTotalCard
            )
            statCard(
                value: "\(stats.inProgressCount)",
                label: "On the table",
                subtitle: "In progress now",
                identifier: A11yID.collectionStatsInProgressCard
            )
            statCard(
                value: "\(stats.backlogCount)",
                label: "On your shelf",
                subtitle: "To-Do puzzles waiting",
                identifier: A11yID.collectionStatsBacklogCard
            )
            if stats.wishlistCount > 0 {
                statCard(
                    value: "\(stats.wishlistCount)",
                    label: "On your wishlist",
                    subtitle: "Want to buy",
                    identifier: A11yID.collectionStatsWishlistCard
                )
            }
            if stats.abandonedCount > 0 {
                statCard(
                    value: "\(stats.abandonedCount)",
                    label: "Abandoned",
                    subtitle: "Will not finish",
                    identifier: A11yID.collectionStatsAbandonedCard
                )
            }
            if let averageDays = stats.formattedAverageDaysToComplete {
                statCard(
                    value: averageDays,
                    label: "Avg. finish time",
                    subtitle: "Start to complete",
                    identifier: A11yID.collectionStatsAverageDaysCard
                )
            }
            if stats.missingPiecesCount > 0 {
                statCard(
                    value: "\(stats.missingPiecesCount)",
                    label: "Missing pieces",
                    subtitle: "Flagged incomplete",
                    identifier: A11yID.collectionStatsMissingPiecesCard
                )
            }
            if let rating = stats.formattedAverageRating {
                statCard(
                    value: rating,
                    label: "Average rating",
                    subtitle: "Completed puzzles with stars",
                    identifier: A11yID.collectionStatsRatingCard
                )
            }
            if let favorite = stats.favoritePieceCount {
                statCard(
                    value: CollectionStats.formatPieceCount(favorite),
                    label: "Go-to piece count",
                    subtitle: "Most common size you finish",
                    identifier: A11yID.collectionStatsFavoritePiecesCard
                )
            }
            if stats.totalMinutesPuzzling > 0 {
                statCard(
                    value: stats.formattedTotalHours,
                    label: "Time at the table",
                    subtitle: "Across completed puzzles",
                    identifier: A11yID.collectionStatsHoursCard
                )
            }
            if let inProgressAvg = stats.formattedAverageInProgress {
                statCard(
                    value: inProgressAvg,
                    label: "Avg. progress",
                    subtitle: "Puzzles on the table",
                    identifier: A11yID.collectionStatsInProgressAvgCard
                )
            }
            if stats.replayedPuzzleCount > 0 {
                statCard(
                    value: "\(stats.replayedPuzzleCount)",
                    label: "Replayed",
                    subtitle: "Finished more than once",
                    identifier: A11yID.collectionStatsReplaysCard
                )
            }
            if let spend = stats.formattedTotalSpend {
                statCard(
                    value: spend,
                    label: "Collection value",
                    subtitle: "Total you've spent",
                    identifier: A11yID.collectionStatsSpendCard
                )
            }
        }
    }

    private var hasHowYouPuzzleContent: Bool {
        stats.favoritePuzzleType != nil
            || stats.favoriteBrand != nil
            || stats.averageDifficulty != nil
            || stats.averageHoursPer1000Pieces != nil
    }

    private var howYouPuzzleSection: some View {
        statsSection(title: "How you puzzle") {
            if let favoriteType = stats.favoritePuzzleType {
                statCard(
                    value: favoriteType.displayLabel,
                    label: "Favorite type",
                    subtitle: "Among completed puzzles",
                    identifier: A11yID.collectionStatsFavoriteTypeCard
                )
            }
            if let favoriteBrand = stats.favoriteBrand {
                statCard(
                    value: favoriteBrand,
                    label: "Favorite brand",
                    subtitle: "Most in your collection",
                    identifier: A11yID.collectionStatsFavoriteBrandCard
                )
            }
            if let difficulty = stats.formattedAverageDifficulty {
                statCard(
                    value: difficulty,
                    label: "Avg. difficulty",
                    subtitle: stats.averageDifficultyDescriptor,
                    identifier: A11yID.collectionStatsAverageDifficultyCard
                )
            }
            if let speed = stats.formattedAverageSpeed {
                statCard(
                    value: speed,
                    label: "Typical pace",
                    subtitle: "Across timed finishes",
                    identifier: A11yID.collectionStatsAverageSpeedCard
                )
            }
        }
    }

    private var yearActivitySection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text("This year")
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .accessibilityAddTraits(.isHeader)

            YearActivityChart(
                monthlyCounts: stats.completionsByMonthThisYear,
                currentMonthIndex: Calendar.current.component(.month, from: Date()) - 1
            )
            .padding(DS.Spacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .brandCardSurface()
            .accessibilityIdentifier(A11yID.collectionStatsYearChart)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DS.Spacing.s3), GridItem(.flexible(), spacing: DS.Spacing.s3)],
                spacing: DS.Spacing.s3
            ) {
                statCard(
                    value: "\(stats.completionsThisMonth)",
                    label: "Finished this month",
                    subtitle: nil,
                    identifier: A11yID.collectionStatsMonthCard
                )
                statCard(
                    value: "\(stats.completionsThisYear)",
                    label: "Finished this year",
                    subtitle: nil,
                    identifier: A11yID.collectionStatsYearCard
                )
                if let best = stats.mostProductiveMonthThisYear {
                    statCard(
                        value: best.label,
                        label: "Busiest month",
                        subtitle: best.count == 1 ? "1 finished" : "\(best.count) finished",
                        identifier: A11yID.collectionStatsBestMonthCard
                    )
                }
            }
        }
    }

    private var paceSection: some View {
        let maxCount = stats.paceBuckets.map(\.count).max() ?? 1
        return VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text("Your pace")
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                ForEach(stats.paceBuckets) { bucket in
                    breakdownRow(name: bucket.label, count: bucket.count, maxCount: maxCount)
                }
            }
            .padding(DS.Spacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .accessibilityIdentifier(A11yID.collectionStatsPaceCard)
        }
    }

    private var shopSection: some View {
        let maxCount = stats.purchaseLocationCounts.map(\.count).max() ?? 1
        return VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text("Where you shop")
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                ForEach(stats.purchaseLocationCounts) { store in
                    breakdownRow(name: store.name, count: store.count, maxCount: maxCount)
                }
            }
            .padding(DS.Spacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .accessibilityIdentifier(A11yID.collectionStatsTopStoresCard)
        }
    }

    private var pieceRangeSection: some View {
        statsSection(title: "Piece counts") {
            if let biggest = stats.biggestCompletedPieces {
                statCard(
                    value: CollectionStats.formatPieceCount(biggest),
                    label: "Biggest completed",
                    subtitle: nil,
                    identifier: A11yID.collectionStatsBiggestCard
                )
            }
            if let smallest = stats.smallestCompletedPieces {
                statCard(
                    value: CollectionStats.formatPieceCount(smallest),
                    label: "Smallest completed",
                    subtitle: nil,
                    identifier: A11yID.collectionStatsSmallestCard
                )
            }
        }
    }

    private var topTagsSection: some View {
        statsSection(title: "Top tags") {
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                ForEach(stats.topTags) { tag in
                    HStack {
                        Text(tag.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.textPrimary)
                        Spacer()
                        Text("\(tag.count)")
                            .font(.subheadline)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(tag.name), \(tag.count) puzzles")
                }
            }
            .padding(DS.Spacing.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
            .optionalAccessibilityIdentifier(A11yID.collectionStatsTopTagsCard)
        }
    }

    private var welcomeHeader: some View {
        Text("Your collection at a glance")
            .font(.title2.weight(.semibold))
            .foregroundStyle(Brand.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    private var emptyState: some View {
        BrandEmptyState(
            systemImage: "puzzlepiece.extension.fill",
            title: "No puzzles yet",
            message: "Add puzzles on the Puzzles tab to see stats here."
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No puzzles yet. Add puzzles on the Puzzles tab to see stats here.")
    }

    // MARK: - Card builders

    private func statsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: DS.Spacing.s3), GridItem(.flexible(), spacing: DS.Spacing.s3)],
                spacing: DS.Spacing.s3
            ) {
                content()
            }
        }
    }

    private func breakdownRow(name: String, count: Int, maxCount: Int) -> some View {
        let fraction = maxCount > 0 ? Double(count) / Double(maxCount) : 0
        return VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.textPrimary)
                Spacer()
                Text("\(count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Brand.cardElevated)
                    Capsule()
                        .fill(Brand.accent)
                        .frame(width: max(6, geo.size.width * fraction))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name), \(count) puzzles")
    }

    private func heroCard(value: String, label: String, icon: String, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Brand.accent)
                .accessibilityHidden(true)

            Text(value)
                .font(.system(.title, design: .rounded).weight(.bold))
                .foregroundStyle(Brand.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .brandCardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel("\(label), \(value)")
    }

    private func statCard(value: String, label: String, subtitle: String?, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Brand.textPrimary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DS.Spacing.s3)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .brandCardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(statAccessibilityLabel(value: value, label: label, subtitle: subtitle))
    }

    private func statAccessibilityLabel(value: String, label: String, subtitle: String?) -> String {
        if let subtitle {
            return "\(label), \(value). \(subtitle)"
        }
        return "\(label), \(value)"
    }
}

// MARK: - StatHighlight

struct StatHighlight: Identifiable {
    let icon: String
    let value: String
    let caption: String

    var id: String { "\(caption)-\(value)" }
}

private struct HighlightChip: View {
    let highlight: StatHighlight

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Image(systemName: highlight.icon)
                .font(.subheadline)
                .foregroundStyle(Brand.accent)
                .accessibilityHidden(true)
            Text(highlight.value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Brand.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(highlight.caption)
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
                .lineLimit(1)
        }
        .padding(DS.Spacing.s3)
        .frame(minWidth: 104, alignment: .leading)
        .brandCardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(highlight.caption), \(highlight.value)")
    }
}

// MARK: - YearActivityChart

private struct YearActivityChart: View {
    let monthlyCounts: [Int]
    let currentMonthIndex: Int

    private var maxCount: Int { max(monthlyCounts.max() ?? 0, 1) }
    private var total: Int { monthlyCounts.reduce(0, +) }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(total == 0 ? "No finishes yet this year" : "\(total) finished so far")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.textPrimary)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(monthlyCounts.enumerated()), id: \.offset) { index, count in
                    bar(count: count, isCurrentMonth: index == currentMonthIndex)
                }
            }
            .frame(height: 88)

            HStack(spacing: 6) {
                ForEach(Array(CollectionStats.monthAbbreviations.enumerated()), id: \.offset) { index, symbol in
                    Text(String(symbol.prefix(1)))
                        .font(.caption2)
                        .foregroundStyle(index == currentMonthIndex ? Brand.accent : Brand.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func bar(count: Int, isCurrentMonth: Bool) -> some View {
        let fraction = Double(count) / Double(maxCount)
        return VStack(spacing: 4) {
            Spacer(minLength: 0)
            if count > 0 {
                Text("\(count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
                    .monospacedDigit()
            }
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(count == 0 ? AnyShapeStyle(Brand.cardElevated)
                      : AnyShapeStyle(isCurrentMonth ? Brand.accentWarm : Brand.accent))
                .frame(height: max(6, CGFloat(fraction) * 64))
        }
        .frame(maxWidth: .infinity)
    }

    private var accessibilityLabel: String {
        guard total > 0 else { return "No puzzles finished yet this year." }
        var parts = ["\(total) puzzles finished this year."]
        let symbols = CollectionStats.monthSymbols
        for (index, count) in monthlyCounts.enumerated() where count > 0 {
            let name = index < symbols.count ? symbols[index] : "month \(index + 1)"
            parts.append("\(name): \(count).")
        }
        return parts.joined(separator: " ")
    }
}

// MARK: - Previews

#Preview {
    CollectionStatsView(ps: PreviewSupport.puzzleStore)
}
