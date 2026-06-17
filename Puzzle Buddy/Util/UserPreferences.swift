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

    static var appearance: AppearancePreference {
        get {
            guard let raw = UserDefaults.standard.string(forKey: appearanceStorageKey),
                  let value = AppearancePreference(rawValue: raw) else {
                return .system
            }
            return value
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: appearanceStorageKey)
        }
    }

    static let barcodeLookupStorageKey = "PuzzleBuddy.BarcodeLookupEnabled"

    static var isBarcodeLookupEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: barcodeLookupStorageKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: barcodeLookupStorageKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: barcodeLookupStorageKey)
        }
    }
}
