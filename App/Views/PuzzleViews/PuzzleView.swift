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

    init(modelContext: ModelContext) {
        _ps = StateObject(wrappedValue: PuzzleStore(modelContext: modelContext))
    }

    var body: some View {
        VStack(spacing: 0) {
            if UserPreferences.isRunningInEphemeralStore, !ephemeralBannerDismissed {
                ephemeralStoreBanner
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

    private var ephemeralStoreBanner: some View {
        HStack(alignment: .top, spacing: DS.Spacing.s3) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Brand.accentWarm)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                Text("Changes won't be saved")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
                Text("Puzzle Buddy couldn't open your saved collection. Anything you add will disappear when you close the app.")
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
            }

            Spacer(minLength: DS.Spacing.s2)

            Button {
                ephemeralBannerDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Dismiss storage warning")
        }
        .padding(DS.Spacing.s3)
        .background(Brand.accentWarm.opacity(0.12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Storage warning. Changes won't be saved between app launches.")
    }
}

// MARK: - Previews
struct PuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleView(modelContext: PreviewSupport.modelContext)
    }
}
