//
//  UITestConstants.swift
//  Puzzle BuddyUITests
//
//  Mirrors app accessibility identifiers and launch arguments without @testable import.
//

import Foundation

enum UITestA11yID {
    static let loginEmailField = "login_email_field"
    static let loginPasswordField = "login_password_field"
    static let loginSubmitButton = "login_submit_button"
    static let puzzleList = "puzzle_list"
    static let addPuzzleButton = "add_puzzle_button"
    static let puzzleDetailSummary = "puzzle_detail_summary"
    static let puzzleDetailStats = "puzzle_detail_stats"
    static let puzzleDetailEditButton = "puzzle_detail_edit_button"
    static let puzzleFormNameField = "puzzle_form_name_field"
    static let puzzleFormSubmitButton = "puzzle_form_submit_button"

    static let seededPuzzleRowLabelPrefix = "Mountain Sunset"
}

enum UITestLaunch {
    static let disableFirebaseAnalytics = "-disable_firebase_analytics"
    static let bypassAuth = "-ui_testing_bypass_auth"
    static let seedPuzzles = "-ui_testing_seed_puzzles"
    static let enableLogin = "-enable_login"

    static let loginArguments = [disableFirebaseAnalytics, enableLogin]
    static let bypassArguments = [disableFirebaseAnalytics, bypassAuth, seedPuzzles]
    static let defaultArguments = [disableFirebaseAnalytics, seedPuzzles]
}
