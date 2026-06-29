//
//  ContentView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/12/22.
//

import SwiftData
import SwiftUI

// MARK: - ContentView
struct PuzzleView: View {
    @StateObject var ps: PuzzleStore
    @AppStorage(UserPreferences.ephemeralStoreBannerDismissedKey) private var ephemeralBannerDismissed = false
    @AppStorage(UserPreferences.storeWasResetNoticePendingKey) private var storeWasResetNoticePending = false

    init(modelContext: ModelContext) {
        _ps = StateObject(wrappedValue: PuzzleStore(modelContext: modelContext))
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsEphemeralStoreBanner {
                ephemeralStoreBanner
            } else if showsStoreResetBanner {
                storeResetBanner
            }
            PuzzleTabbar(ps: ps)
        }
        .task {
            if MarketingSnapshotBootstrap.shouldResetCollection {
                try? ps.clearAllPuzzles()
            }
            if UITestSupport.shouldSeedPuzzles, ps.puzzles.isEmpty {
                try? ps.loadDemoPuzzles()
            } else if ps.puzzles.isEmpty {
                await ps.fetchPuzzles()
            }
        }
    }

    /// Only warn real users about data loss. The in-memory store is also used
    /// intentionally for UI tests and marketing snapshots, where the banner is noise.
    private var showsEphemeralStoreBanner: Bool {
        UserPreferences.isRunningInEphemeralStore
            && !ephemeralBannerDismissed
            && !UITestSupport.isRunningUnderTest
    }

    /// Shown once after an unreadable on-disk store was wiped and rebuilt, so the user
    /// knows their previous collection is gone but new puzzles will save normally.
    private var showsStoreResetBanner: Bool {
        storeWasResetNoticePending && !UITestSupport.isRunningUnderTest
    }

    private var ephemeralStoreBanner: some View {
        noticeBanner(
            title: "Changes won't be saved",
            message: "Puzzle Buddy couldn't open your saved collection. Anything you add will disappear when you close the app.",
            dismissLabel: "Dismiss storage warning",
            accessibilityLabel: "Storage warning. Changes won't be saved between app launches.",
            onDismiss: { ephemeralBannerDismissed = true }
        )
    }

    private var storeResetBanner: some View {
        noticeBanner(
            title: "Collection was reset",
            message: "We couldn't open your previous collection, so Puzzle Buddy started fresh. New puzzles you add will save normally.",
            dismissLabel: "Dismiss collection reset notice",
            accessibilityLabel: "Notice. Your previous collection could not be opened and was reset. New puzzles will save normally.",
            onDismiss: { storeWasResetNoticePending = false }
        )
    }

    private func noticeBanner(
        title: String,
        message: String,
        dismissLabel: String,
        accessibilityLabel: String,
        onDismiss: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.s3) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Brand.accentWarm)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
            }

            Spacer(minLength: DS.Spacing.s2)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel(dismissLabel)
        }
        .padding(DS.Spacing.s3)
        .background(Brand.accentWarm.opacity(0.12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Previews
struct PuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleView(modelContext: PreviewSupport.modelContext)
    }
}
