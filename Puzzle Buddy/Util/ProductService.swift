//
//  ProductService.swift
//  Puzzle Buddy
//
//  Feature flags for staged releases. Login/cloud sync ships after 1.0.
//

import Foundation

enum ProductService {
    private static let enableLoginArgument = "-enable_login"

    /// Account sign-in and Firestore sync. Off for 1.0 local-only release.
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
}
