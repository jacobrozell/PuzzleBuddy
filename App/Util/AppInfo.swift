//
//  AppInfo.swift
//  Puzzle Buddy
//

import Foundation

/// User-facing app identity.
enum AppInfo {
    static let displayName = "Puzzle Buddy"

    static var isUITesting: Bool {
        UITestSupport.isRunningUnderTest
    }
}
