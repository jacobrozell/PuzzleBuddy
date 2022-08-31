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
    @State private var showCreateAccount = true

    /// User init
    init(user: PuzzleUser) {
        _ps = StateObject(wrappedValue: PuzzleStore(user: user))
    }

    /// Bypass
    init() {
        _ps = StateObject(wrappedValue: PuzzleStore())
    }

    var body: some View {
        PuzzleList(ps: ps)
            .navigationViewStyle(.stack)
            .navigationTitle(Text("Welcome \(auth.user?.displayName ?? "Anon")!"))
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        present.toggle()
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProfileOptions = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $present) {
                PuzzleForm(ps: ps, isPresented: $present)
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
                        NavigationLink {
                            CreateAccount(isActive: $showCreateAccount)
                        } label: {
                            Text("Create Account")
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
