//
//  UserPreferences.swift
//  Puzzle Buddy
//

import SwiftUI

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum UserPreferences {
    static let appearanceStorageKey = "PuzzleBuddy.AppearancePreference"
    static let ephemeralStoreBannerDismissedKey = "PuzzleBuddy.EphemeralStoreBannerDismissed"
    static let storeWasResetNoticePendingKey = "PuzzleBuddy.StoreWasResetNoticePending"

    /// True when SwiftData fell back to an in-memory store (changes won't survive relaunch).
    static var isRunningInEphemeralStore = false

    /// Records that an unreadable on-disk store was wiped and rebuilt fresh, so the user
    /// can be told their previous collection could not be recovered. Persists until dismissed.
    static func markStoreWasReset() {
        UserDefaults.standard.set(true, forKey: storeWasResetNoticePendingKey)
    }
}
