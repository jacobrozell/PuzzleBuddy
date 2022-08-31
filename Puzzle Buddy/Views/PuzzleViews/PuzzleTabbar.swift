//
//  PuzzleTabbar.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

// MARK: - PuzzleTabbar
struct PuzzleTabbar: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @ObservedObject var ps: PuzzleStore
    @State private var showProfileOptions = false
    @State private var showCreateAccount = false

    var body: some View {
        TabView {
            PuzzleListWrapper(ps: ps)
            .tabItem {
                Label {
                    Text("Puzzles")
                } icon: {
                    Image(systemName: "list.bullet.circle.fill")
                }
            }

            SettingsView()
            .tabItem {
                Label {
                    Text("Settings")
                } icon: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .popover(isPresented: $showCreateAccount) {
            CreateAccount(isActive: $showCreateAccount)
        }
        .confirmationDialog("Profile Options", isPresented: $showProfileOptions) {
            VStack {
                if let _ = auth.user {
                    Button {
                        do {
                            try auth.logout()
                        } catch {
                            eh.handle(title: "Logout failed", message: "Whoops")
                        }
                    } label: {
                        Text("Sign-Out")
                    }
                }

                if auth.shouldBypassAccount {
                    Button {
                        showCreateAccount = true
                    } label: {
                        Text("Create Account")
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showProfileOptions = true
                } label: {
                    Image(systemName: "person.circle.fill")
                }
            }
        }
    }
}

struct PuzzleTabbar_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleTabbar(ps: .init())
    }
}
