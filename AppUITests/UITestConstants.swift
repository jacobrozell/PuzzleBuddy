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
    static let puzzleListFilterButton = "puzzle_list_filter_button"
    static let puzzleListSortMenu = "puzzle_list_sort_menu"
    static let settingsLoadDemoButton = "settings_load_demo_button"
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
    static let onboardingPager = "onboarding_pager"
    static let onboardingSkipButton = "onboarding_skip_button"
    static let onboardingNextButton = "onboarding_next_button"
    static let onboardingBackButton = "onboarding_back_button"
    static let onboardingFinishButton = "onboarding_finish_button"
    static let whatsNewSheet = "whats_new_sheet"
    static let whatsNewDismissButton = "whats_new_dismiss_button"
    static let puzzleListOverdueFilter = "puzzle_list_overdue_filter"
    static let puzzleDetailUndoCompletionBanner = "puzzle_detail_undo_completion_banner"
    static let puzzleDetailUndoCompletionButton = "puzzle_detail_undo_completion_button"
    static let puzzleDetailCompletionHistory = "puzzle_detail_completion_history"
    static let puzzleDetailProgressSlider = "puzzle_detail_progress_slider"
    static let puzzleDetailCompletionRemoveButton = "puzzle_detail_completion_remove_button"

    static func puzzleDetailCompletionRow(number: Int) -> String {
        "puzzle_detail_completion_\(number)"
    }

    static let seededPuzzleRowLabelPrefix = "The Bizarre Bookshop"
}

enum UITestLaunch {
    static let disableFirebaseAnalytics = "-disable_firebase_analytics"
    static let bypassOnboarding = "-ui_testing_bypass_onboarding"
    static let seedPuzzles = "-ui_testing_seed_puzzles"
    static let uiTestReset = "-ui_test_reset"
    static let snapshotOnboarding = "-snapshot_onboarding"
    static let showWhatsNew = "-ui_testing_show_whats_new"

    static let bypassArguments = [disableFirebaseAnalytics, bypassOnboarding, seedPuzzles]
    static let defaultArguments = [disableFirebaseAnalytics, seedPuzzles]
    /// Forces first-run carousel without bypassing it (`-snapshot_onboarding` wins over test auto-complete).
    static let onboardingArguments = [disableFirebaseAnalytics, uiTestReset, snapshotOnboarding]
}
