//
//  Puzzle_BuddyApp.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/12/22.
//

import FirebaseAuth
import SwiftUI


@main
struct Puzzle_BuddyApp: App {
    public static let version = "0.3.0"

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authProvider = FirebaseAuthProvider()

    var body: some Scene {
        WindowGroup {
            LoginView()
                .withErrorHandling()
                .environmentObject(authProvider)
                .task {
                    authProvider.user = Auth.auth().currentUser

                    // Update User
                    Task {
                        do {
                            try await authProvider.updateUser()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
        }
    }
}
