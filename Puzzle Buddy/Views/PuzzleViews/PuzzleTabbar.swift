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
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @ObservedObject var ps: PuzzleStore

    @State private var tab: PuzzleBuddyTab = .puzzles

    var body: some View {
        NavigationStack {
            TabView(selection: $tab) {
                PuzzleList(ps: ps)
                    .tag(PuzzleBuddyTab.puzzles)
                    .tabItem {
                        Label {
                            Text("Puzzles")
                        } icon: {
                            Image(systemName: "list.bullet.circle.fill")
                        }
                    }
                    .accessibilityIdentifier(A11yID.puzzlesTab)

                CollectionStatsView(ps: ps)
                    .tag(PuzzleBuddyTab.stats)
                    .tabItem {
                        Label {
                            Text("Stats")
                        } icon: {
                            Image(systemName: "chart.bar.fill")
                        }
                    }
                    .accessibilityIdentifier(A11yID.statsTab)

                SettingsView()
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
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(tab.rawValue)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .brandBackground()
            .tint(Brand.accent)
        }
    }
}

struct PuzzleTabbar_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleTabbar(ps: PreviewSupport.puzzleStore)
    }
}
