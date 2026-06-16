//
//  Puzzle_BuddyApp.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/12/22.
//

import SwiftData
import SwiftUI

@main
struct Puzzle_BuddyApp: App {
    public static let version = "1.0.0"

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authProvider = FirebaseAuthProvider()

    var body: some Scene {
        WindowGroup {
            AppShell(modelContext: sharedModelContainer.mainContext)
                .withErrorHandling()
                .environmentObject(authProvider)
        }
        .modelContainer(sharedModelContainer)
    }

    private var sharedModelContainer: ModelContainer = {
        PuzzleModelContainer.makePersistent()
    }()
}
