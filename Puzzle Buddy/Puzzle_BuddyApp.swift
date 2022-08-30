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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authProvider = FirebaseAuthProvider()

    var body: some Scene {
        WindowGroup {
            LoginView()
                .withErrorHandling()
                .environmentObject(authProvider)
                .task {
                    authProvider.user = Auth.auth().currentUser
                }
        }
    }
}
