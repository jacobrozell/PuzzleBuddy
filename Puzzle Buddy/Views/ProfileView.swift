//
//  ProfileView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 5/2/23.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @ObservedObject var ps: PuzzleStore

    @State private var updateUsernamePresent = false
    @Binding var showProfile: Bool

    var body: some View {
        if let user = ps.puzzleUser {
            Section {
                Form {
                    Text("\(user.email!)")

                    Button {
                        Task {
                            try await ps.sendResetPassword()
                        }
                    } label: {
                        Text("Change Password")
                    }

                    Button {
                        updateUsernamePresent.toggle()
                    } label: {
                        Text("Change Username")
                    }
                    .sheet(isPresented: $updateUsernamePresent) {
                        NavigationView {
                            ChangeUsernameView()
                                .withErrorHandling()
                        }
                    }
                }
            } header: {
                Text("Welcome \(user.displayName ?? "")!")
            } footer: {
                Button {
                    showProfile.toggle()
                } label: {
                    Text("Close")
                        .underline()
                        .padding(.vertical)
                }
            }
        }
    }
}

//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//
//    }
//}
