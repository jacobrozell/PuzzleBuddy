//
//  SettingsView.swift
//  Puzzle Buddy
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling

    var body: some View {
        List {
            if ProductService.isLoginEnabled {
                Section {
                    if auth.user != nil {
                        Button {
                            do {
                                try auth.logout()
                            } catch {
                                eh.handle(title: "Logout failed", message: error.localizedDescription)
                            }
                        } label: {
                            Text("Sign Out")
                                .foregroundStyle(Brand.accentWarm)
                        }
                        .optionalAccessibilityIdentifier(A11yID.settingsSignOutButton)
                        .accessibilityLabel("Sign out")
                        .accessibilityHint("Signs out of your Puzzle Buddy account")
                    }
                } header: {
                    Text("Account")
                }
            }

            Section {
                Link("Privacy Policy", destination: URL(string: "https://jacobrozell.github.io/PuzzleBuddy/privacy.html")!)
                Link("Support", destination: URL(string: "https://jacobrozell.github.io/PuzzleBuddy/support.html")!)
                Link("Accessibility", destination: URL(string: "https://jacobrozell.github.io/PuzzleBuddy/accessibility.html")!)
            } header: {
                Text("Help & Legal")
            }

            Section {
                LabeledContent("Version", value: Puzzle_BuddyApp.version)
            } header: {
                Text("About")
            }
        }
        .readableBrandScreenChrome()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
