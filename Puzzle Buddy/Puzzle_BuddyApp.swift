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
    @StateObject var eh = ErrorHandling()
    @StateObject var auth = FirebaseAuthProvider()

    var body: some Scene {
        WindowGroup {
            LoginView()
                .environmentObject(eh)
                .environmentObject(auth)
                .withErrorHandling()
                .task {
                    auth.user = Auth.auth().currentUser
                }
        }
    }
}
