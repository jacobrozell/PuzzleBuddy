//
//  ProfileView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 5/2/23.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @ObservedObject var ps: PuzzleStore

    @State private var updateUsernamePresent = false
    @Binding var showProfile: Bool

    var body: some View {
        if let user = ps.puzzleUser {
            Section {
                Form {
                    Text("\(user.email!)")
                        .accessibilityLabel("Account email, \(user.email!)")

                    Button {
                        Task {
                            do {
                                try await auth.sendResetPassword()
                                eh.handle(title: "Password Reset", message: "A password reset email has been sent.")
                            } catch {
                                eh.handle(title: "Password Reset Failed", message: error.localizedDescription)
                            }
                        }
                    } label: {
                        Text("Change Password")
                    }
                    .accessibilityLabel("Send password reset email")

                    Button {
                        updateUsernamePresent.toggle()
                    } label: {
                        Text("Change Username")
                    }
                    .accessibilityLabel("Change display name")
                    .sheet(isPresented: $updateUsernamePresent) {
                        NavigationView {
                            ChangeUsernameView()
                                .withErrorHandling()
                        }
                    }
                }
            } header: {
                Text("Welcome \(user.displayName ?? "")!")
                    .accessibilityAddTraits(.isHeader)
            } footer: {
                Button {
                    showProfile.toggle()
                } label: {
                    Text("Close")
                        .underline()
                        .padding(.vertical)
                }
                .accessibilityLabel("Close profile")
            }
        }
        // TODO else
    }
}

//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//
//    }
//}
