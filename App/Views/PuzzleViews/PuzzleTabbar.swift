//
//  PuzzleTabbar.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftData
import SwiftUI

private enum PuzzleBuddyTab: String {
    case puzzles = "Puzzle Buddy"
    case stats = "Collection Stats"
    case settings = "Settings"
}

// MARK: - PuzzleTabbar
struct PuzzleTabbar: View {
    @EnvironmentObject var eh: ErrorHandling
    @ObservedObject var ps: PuzzleStore

    @State private var tab: PuzzleBuddyTab = {
        switch MarketingSnapshotBootstrap.forcedTab {
        case .stats: .stats
        case .settings: .settings
        default: .puzzles
        }
    }()

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                PuzzleList(ps: ps)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle(PuzzleBuddyTab.puzzles.rawValue)
            }
            .tag(PuzzleBuddyTab.puzzles)
            .tabItem {
                Label {
                    Text("Puzzles")
                } icon: {
                    Image(systemName: "list.bullet.circle.fill")
                }
            }
            .accessibilityIdentifier(A11yID.puzzlesTab)

            NavigationStack {
                CollectionStatsView(ps: ps)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle(PuzzleBuddyTab.stats.rawValue)
            }
            .tag(PuzzleBuddyTab.stats)
            .tabItem {
                Label {
                    Text("Stats")
                } icon: {
                    Image(systemName: "chart.bar.fill")
                }
            }
            .accessibilityIdentifier(A11yID.statsTab)

            NavigationStack {
                SettingsView(ps: ps)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle(PuzzleBuddyTab.settings.rawValue)
            }
            .tag(PuzzleBuddyTab.settings)
            .tabItem {
                Label {
                    Text("Settings")
                } icon: {
                    Image(systemName: "gearshape")
                }
            }
            .accessibilityIdentifier(A11yID.settingsTab)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .brandBackground()
        .tint(Brand.accent)
        .onAppear {
            MarketingSnapshotBootstrap.reinforceTabSelection { snapshotTab in
                switch snapshotTab {
                case .puzzles: tab = .puzzles
                case .stats: tab = .stats
                case .settings: tab = .settings
                }
            }
        }
        .onChange(of: tab) { _, newTab in
            AppLog.shared.info(
                .ui,
                eventName: "tab_selected",
                message: "Tab selected.",
                metadata: ["tab": analyticsTabID(for: newTab)]
            )
        }
    }

    private func analyticsTabID(for tab: PuzzleBuddyTab) -> String {
        switch tab {
        case .puzzles: return "puzzles"
        case .stats: return "stats"
        case .settings: return "settings"
        }
    }
}

struct PuzzleTabbar_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleTabbar(ps: PreviewSupport.puzzleStore)
    }
}
