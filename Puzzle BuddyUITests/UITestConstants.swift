//
//  UITestConstants.swift
//  Puzzle BuddyUITests
//
//  Mirrors app accessibility identifiers and launch arguments without @testable import.
//

import XCTest

enum UITestA11yID {
    static let loginEmailField = "login_email_field"
    static let loginPasswordField = "login_password_field"
    static let loginSubmitButton = "login_submit_button"
    static let puzzleList = "puzzle_list"
    static let puzzleListStatusFilter = "puzzle_list_status_filter"
    static let puzzleListEmptyState = "puzzle_list_empty_state"
    static let puzzleListSearchField = "puzzle_list_search_field"
    static let puzzleListSortMenu = "puzzle_list_sort_menu"
    static let addPuzzleButton = "add_puzzle_button"
    static let puzzleDetailSummary = "puzzle_detail_summary"
    static let puzzleDetailStats = "puzzle_detail_stats"
    static let puzzleDetailPaceRow = "puzzle_detail_pace_row"
    static let puzzleDetailHoursPer1000Row = "puzzle_detail_hours_per_1000_row"
    static let puzzleDetailEditButton = "puzzle_detail_edit_button"
    static let puzzleFormNameField = "puzzle_form_name_field"
    static let puzzleFormRatingControl = "puzzle_form_rating_control"
    static let puzzleFormSubmitButton = "puzzle_form_submit_button"
    static let collectionStatsScreen = "collection_stats_screen"
    static let collectionStatsCompletedCard = "collection_stats_completed_card"

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

enum LoginUITestGate {
    /// Login UI is built but gated off for 1.0; full login UI tests run in Release 1.x QA with Firebase configured.
    static func skipForLocalFirstRelease(file: StaticString = #filePath, line: UInt = #line) throws {
        throw XCTSkip(
            "Login UI tests are deferred to Release 1.x QA (Firebase + -enable_login).",
            file: file,
            line: line
        )
    }
}
