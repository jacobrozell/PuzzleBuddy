//
//  ContentView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/12/22.
//

import FirebaseAuth
import SwiftUI

// MARK: - ContentView
struct PuzzleView: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @StateObject var ps: PuzzleStore
    @State private var present = false
    @State private var showProfileOptions = false
    @State private var showCreateAccount = false

    /// User init
    init(user: PuzzleUser) {
        _ps = StateObject(wrappedValue: PuzzleStore(user: user))
    }

    /// Bypass
    init() {
        _ps = StateObject(wrappedValue: PuzzleStore())
    }

    var body: some View {
        NavigationView {
            TabView {
                VStack {
                    PuzzleList(ps: ps)
                        .navigationViewStyle(.columns)
                        .navigationTitle(Text("Welcome \(auth.user?.displayName ?? "Anon")!"))
                        .sheet(isPresented: $present) {
                            PuzzleForm(ps: ps, isPresented: $present)
                        }

                    Button {
                        present.toggle()
                    } label: {
                        Image(systemName: "plus.circle")
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                    }
                    .padding()
                }
                .tabItem {
                    Label {
                        Text("Puzzles")
                    } icon: {
                        Image(systemName: "list.bullet.circle.fill")
                    }
                }

                VStack {
                    Text("Settings")
                        .navigationTitle("Settings")
                }
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
}

struct CPuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleView()
    }
}
