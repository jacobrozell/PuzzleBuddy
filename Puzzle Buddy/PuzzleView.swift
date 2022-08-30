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

    init(user: PuzzleUser) {
        _ps = StateObject(wrappedValue: PuzzleStore(user: user))
    }

    var body: some View {
        PuzzleList(ps: ps)
            .navigationViewStyle(.stack)
            .navigationTitle(Text("Puzzle Buddy"))
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
                    Button {
                        do {
                            try auth.logout()
                        } catch {
                            eh.handle(title: "Logout failed", message: "Whoops")
                        }
                    } label: {
                        Text("Signout")
                    }
                }
            }
    }
}
//
//struct CPuzzleView_Previews: PreviewProvider {
//    static var previews: some View {
//        PuzzleView(user: .fixture())
//    }
//}
