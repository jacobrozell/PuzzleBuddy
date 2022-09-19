//
//  PuzzleTabbar.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

private enum PuzzleBuddyTab: String {
    case puzzles = "Puzzle Buddy"
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
                    .navigationTitle(PuzzleBuddyTab.puzzles.rawValue)
                    .tabItem {
                        Label {
                            Text("Puzzles")
                        } icon: {
                            Image(systemName: "list.bullet.circle.fill")
                        }
                    }

                SettingsView()
                    .tag(PuzzleBuddyTab.settings)
                    .navigationTitle(PuzzleBuddyTab.settings.rawValue)
                    .tabItem {
                        Label {
                            Text("Settings")
                        } icon: {
                            Image(systemName: "gearshape")
                        }
                    }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(tab.rawValue)
        }
    }
}

struct PuzzleTabbar_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleTabbar(ps: .init())
    }
}
