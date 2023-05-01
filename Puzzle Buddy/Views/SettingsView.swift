//
//  SettingsView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/31/22.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling

    @State private var deleteConfirmation = false
    @State private var deleteScreen = false

    var body: some View {
        List {
            Section {
                if let _ = auth.user {
                    Button {
                        Task {
                            do {
                                try await auth.logout()
                            } catch {
                                eh.handle(title: "Logout failed", message: "Whoops")
                            }
                        }
                    } label: {
                        Text("Sign-Out")
                    }
                }

                // Export Data

                // Reset Password

            } header: {
                Text("Account Settings")
            }

            // Notification Settings


            // Delete Account
            Button(role: .destructive) {
                deleteConfirmation.toggle()
            } label: {
                Text("Delete Account")
            }
            .confirmationDialog("", isPresented: $deleteConfirmation, actions: {
                Button(role: .destructive) {
                    auth.deleteAccount()
                } label: {
                    Text("I am sure.")
                }
            }, message: {
                Text("Are you sure you want to delete your account?")
            })
            .sheet(isPresented: $auth.shouldReauth) {
                Text("You need to re-authenticate before you can delete your account.")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .underline()

                GroupBox {
                    LoginStack()
                        .environmentObject(auth)
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
