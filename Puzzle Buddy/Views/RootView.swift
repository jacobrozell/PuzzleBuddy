//
//  RootView.swift
//  Puzzle Buddy
//

import FirebaseAuth
import SwiftData
import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    let modelContext: ModelContext

    var body: some View {
        Group {
            if ProductService.isLoginEnabled {
                LoginView(modelContext: modelContext)
            } else {
                PuzzleView(modelContext: modelContext)
            }
        }
        .task {
            if UITestSupport.isBypassAuthEnabled {
                auth.shouldBypassAccount = true
            } else if ProductService.isLoginEnabled, FirebaseBootstrap.shouldConfigure {
                auth.user = Auth.auth().currentUser
            }
            AppLog.shared.info(.app, eventName: "app_bootstrap_ready", message: "Puzzle Buddy launched.")

            guard ProductService.isLoginEnabled,
                  !auth.shouldBypassAccount,
                  FirebaseBootstrap.shouldConfigure,
                  auth.user != nil
            else { return }

            do {
                try await auth.updateUser()
            } catch {
                AppLog.shared.warning(.auth, eventName: "auth_failed", message: error.localizedDescription)
            }
        }
    }
}
