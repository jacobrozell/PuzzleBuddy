//
//  ProductService.swift
//  Puzzle Buddy
//
//  Feature flags for staged releases.
//

import Foundation

enum ProductService {
    /// Live barcode scanner (VisionKit). Requires camera hardware.
    @MainActor
    static var isBarcodeScanEnabled: Bool {
        BarcodeScannerSupport.isAvailable
    }

    /// Shopping duplicate-check mode (offline, no product lookup).
    static var isShoppingModeEnabled: Bool {
        true
    }

    /// "Pick my next puzzle" random selector (1.0).
    static var isPickNextEnabled: Bool {
        true
    }

    /// Settings Friends / People list. Model + FriendStore ship with On loan; UI stays off until ready.
    static var isFriendsListEnabled: Bool {
        false
    }
}
