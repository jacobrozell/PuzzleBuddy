//
//  UITestConstants.swift
//  Puzzle BuddyUITests
//
//  Mirrors app accessibility identifiers and launch arguments without @testable import.
//

import XCTest

enum UITestA11yID {
    static let puzzleList = "puzzle_list"
    static let puzzleListStatusFilter = "puzzle_list_status_filter"
    static let puzzleListEmptyState = "puzzle_list_empty_state"
    static let puzzleListSearchField = "puzzle_list_search_field"
    static let puzzleListSortMenu = "puzzle_list_sort_menu"
    static let addPuzzleButton = "add_puzzle_button"
    static let addPuzzleFloatingButton = "add_puzzle_floating_button"
    static let puzzleDetailSummary = "puzzle_detail_summary"
    static let puzzleDetailStats = "puzzle_detail_stats"
    static let puzzleDetailPaceRow = "puzzle_detail_pace_row"
    static let puzzleDetailHoursPer1000Row = "puzzle_detail_hours_per_1000_row"
    static let puzzleDetailEditButton = "puzzle_detail_edit_button"
    static let puzzleDetailRedoButton = "puzzle_detail_redo_button"
    static let puzzleFormNameField = "puzzle_form_name_field"
    static let puzzleFormChoosePhotoButton = "puzzle_form_choose_photo_button"
    static let puzzleFormRatingControl = "puzzle_form_rating_control"
    static let puzzleFormSubmitButton = "puzzle_form_submit_button"
    static let collectionStatsScreen = "collection_stats_screen"
    static let splashScreen = "splash_screen"
    static let collectionStatsCompletedCard = "collection_stats_completed_card"
    static let settingsImportIPDbButton = "settings_import_ipdb_button"
    static let settingsExportCollectionButton = "settings_export_collection_button"

    static let seededPuzzleRowLabelPrefix = "The Bizarre Bookshop"
}

enum UITestLaunch {
    static let disableFirebaseAnalytics = "-disable_firebase_analytics"
    static let bypassOnboarding = "-ui_testing_bypass_onboarding"
    static let seedPuzzles = "-ui_testing_seed_puzzles"

    static let bypassArguments = [disableFirebaseAnalytics, bypassOnboarding, seedPuzzles]
    static let defaultArguments = [disableFirebaseAnalytics, seedPuzzles]
}
