//
//  PuzzleBuddyApp.swift
//  PuzzleBuddy
//
//  Created by Jacob Rozell on 7/12/22.
//

import SwiftData
import SwiftUI

@main
struct PuzzleBuddyApp: App {
    public static let version = "1.0.0" // Keep in sync with MARKETING_VERSION in project.yml

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage(UserPreferences.appearanceStorageKey) private var appearanceRaw = AppearancePreference.system.rawValue

    private var preferredColorScheme: ColorScheme? {
        AppearancePreference(rawValue: appearanceRaw)?.colorScheme
    }

    var body: some Scene {
        WindowGroup {
            AppShell(modelContext: sharedModelContainer.mainContext)
                .withErrorHandling()
                .preferredColorScheme(preferredColorScheme)
                .task {
                    SnapshotOrientationLock.applyIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private var sharedModelContainer: ModelContainer = {
        PuzzleModelContainer.makePersistent()
    }()
}
