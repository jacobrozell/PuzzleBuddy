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
                    collectionSection
                    if stats.favoritePuzzleType != nil || !stats.topPurchaseLocations.isEmpty {
                        howYouPuzzleSection
                    }
                    periodSection
                    if stats.biggestCompletedPieces != nil || stats.smallestCompletedPieces != nil {
                        pieceRangeSection
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
            PickNextPuzzleView(ps: ps)
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
        }
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
            if let topStore = stats.topPurchaseLocations.first {
                statCard(
                    value: topStore,
                    label: "Top store",
                    subtitle: stats.topPurchaseLocations.count > 1 ? "Most puzzles bought here" : nil,
                    identifier: A11yID.collectionStatsTopStoreCard
                )
            }
        }
    }

    private var periodSection: some View {
        statsSection(title: "This year") {
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
        VStack(spacing: DS.Spacing.s3) {
            Image(systemName: "puzzlepiece.extension.fill")
                .font(.system(size: 44))
                .foregroundStyle(Brand.accent)
                .accessibilityHidden(true)

            Text("No puzzles yet")
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)

            Text("Add puzzles on the Puzzles tab to see stats here.")
                .font(.body)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DS.Spacing.s5)
        .frame(maxWidth: .infinity)
        .brandCardSurface()
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

// MARK: - Previews

#Preview {
    CollectionStatsView(ps: PreviewSupport.puzzleStore)
}
