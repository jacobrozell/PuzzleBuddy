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
    public static let version = "0.4.1"

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authProvider = FirebaseAuthProvider()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                LoginView()
                    .withErrorHandling()
                    .environmentObject(authProvider)
                    .task {
                        authProvider.user = Auth.auth().currentUser
                    }
            }
        }
    }
}
