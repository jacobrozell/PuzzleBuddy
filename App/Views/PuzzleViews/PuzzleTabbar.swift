//
//  PuzzleTabbar.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftData
import SwiftUI

private enum PuzzleBuddyTab: String, Hashable {
    case puzzles = "Puzzle Buddy"
    case stats = "Collection Stats"
    case settings = "Settings"
}

// MARK: - PuzzleTabbar
struct PuzzleTabbar: View {
    @EnvironmentObject var eh: ErrorHandling
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var ps: PuzzleStore

    @State private var tab: PuzzleBuddyTab = {
        switch MarketingSnapshotBootstrap.forcedTab {
        case .stats: .stats
        case .settings: .settings
        default: .puzzles
        }
    }()

    private var usesSplitNavigation: Bool {
        AdaptiveLayout.usesSplitNavigation(horizontalSizeClass: horizontalSizeClass)
    }

    var body: some View {
        TabView(selection: $tab) {
            Tab(value: PuzzleBuddyTab.puzzles) {
                Group {
                    if usesSplitNavigation {
                        PuzzleList(ps: ps)
                            .background(Brand.background.ignoresSafeArea())
                    } else {
                        NavigationStack {
                            PuzzleList(ps: ps)
                        }
                    }
                }
            } label: {
                Label("Puzzles", systemImage: "list.bullet.circle.fill")
            }
            .accessibilityIdentifier(A11yID.puzzlesTab)

            Tab(value: PuzzleBuddyTab.stats) {
                NavigationStack {
                    CollectionStatsView(ps: ps)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle(PuzzleBuddyTab.stats.rawValue)
                }
            } label: {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .accessibilityIdentifier(A11yID.statsTab)

            Tab(value: PuzzleBuddyTab.settings) {
                NavigationStack {
                    SettingsView(ps: ps)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle(PuzzleBuddyTab.settings.rawValue)
                }
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .accessibilityIdentifier(A11yID.settingsTab)
        }
        .tabViewStyle(.sidebarAdaptable)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(PuzzleTabRootChrome(regularWidth: usesSplitNavigation))
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
