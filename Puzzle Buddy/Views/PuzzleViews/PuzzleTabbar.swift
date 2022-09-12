//
//  PuzzleTabbar.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

private enum PuzzleBuddyTab: String {
    case puzzles = "Your Puzzle Buddy"
    case settings = "Settings"
}

// MARK: - PuzzleTabbar
struct PuzzleTabbar: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @ObservedObject var ps: PuzzleStore

    @State private var tab: PuzzleBuddyTab = .puzzles

    var body: some View {
        NavigationView {
            TabView(selection: $tab) {
                PuzzleListWrapper(ps: ps)
                    .tabItem {
                        Label {
                            Text("Puzzles")
                        } icon: {
                            Image(systemName: "list.bullet.circle.fill")
                        }
                    }
                    .tag(PuzzleBuddyTab.puzzles)

                SettingsView()
                    .tabItem {
                        Label {
                            Text("Settings")
                        } icon: {
                            Image(systemName: "gearshape")
                        }
                    }
                    .tag(PuzzleBuddyTab.settings)
            }
            .tabViewStyle(.automatic)
            .navigationViewStyle(.stack)
            .navigationTitle(tab.rawValue)
            .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

struct PuzzleTabbar_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleTabbar(ps: .init())
    }
}
