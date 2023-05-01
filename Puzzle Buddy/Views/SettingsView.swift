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

    var body: some View {
        List {
            Section {
                if let user = auth.user {
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

                // Delete Account

                // Export Data

                // Reset Password

            } header: {
                Text("Account Settings")
            }

            // Notification Settings
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
