//
//  ProductService.swift
//  Puzzle Buddy
//
//  Feature flags for staged releases. Login/cloud sync ships after 1.0.
//

import Foundation

enum ProductService {
    private static let enableLoginArgument = "-enable_login"
    private static let disableBarcodeLookupArgument = "-disable_barcode_lookup"

    /// Account sign-in and Firestore sync. Off for 1.0.0 local-only release.
    static var isLoginEnabled: Bool {
        if ProcessInfo.processInfo.arguments.contains(enableLoginArgument) {
            return true
        }
        if UITestSupport.isBypassAuthEnabled {
            return false
        }
        return false
    }

    static var isCloudSyncEnabled: Bool {
        isLoginEnabled && FirebaseBootstrap.shouldConfigure
    }

    /// Live barcode scanner (VisionKit). Requires camera hardware.
    @MainActor
    static var isBarcodeScanEnabled: Bool {
        BarcodeScannerSupport.isAvailable
    }

    /// Shopping duplicate-check mode (offline, no product lookup).
    static var isShoppingModeEnabled: Bool {
        true
    }

    /// Import puzzles from an IPDb CSV export (Settings → Collection).
    static var isIPDbImportEnabled: Bool {
        true
    }

    /// Online UPC metadata lookup via UPCitemdb trial API (100 requests/day).
    static var isBarcodeLookupEnabled: Bool {
        if ProcessInfo.processInfo.arguments.contains(disableBarcodeLookupArgument) {
            return false
        }
        return UserPreferences.isBarcodeLookupEnabled
    }
}
