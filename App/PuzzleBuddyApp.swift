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
    public static let version = "1.2.0" // Keep in sync with MARKETING_VERSION in project.yml

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage(UserPreferences.appearanceStorageKey) private var appearanceRaw = AppearancePreference.system.rawValue

    private var preferredColorScheme: ColorScheme? {
        if let forced = MarketingSnapshotBootstrap.forcedAppearance {
            return forced.colorScheme
        }
        return AppearancePreference(rawValue: appearanceRaw)?.colorScheme
    }

    var body: some Scene {
        WindowGroup {
            AppShell(modelContext: sharedModelContainer.mainContext)
                .withErrorHandling()
                .preferredColorScheme(preferredColorScheme)
                .background(Brand.background.ignoresSafeArea())
                .brandWindowBackground()
                .task {
                    SnapshotOrientationLock.applyIfNeeded()
                    TipJarStore.shared.start()
                }
                .onOpenURL { url in
                    WidgetDeepLink.remember(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private var sharedModelContainer: ModelContainer = {
        PuzzleModelContainer.makePersistent()
    }()
}
