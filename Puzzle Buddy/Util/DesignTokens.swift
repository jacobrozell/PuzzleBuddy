//
//  DesignTokens.swift
//  Puzzle Buddy
//
//  Shared visual tokens aligned with Dart Buddy / MiniMuster-style polish.
//

import SwiftUI
import UIKit

// MARK: - Brand palette
// Source of truth: Resources/loading-animation-source/puzzle-scene.jsx + Scripts/render-app-icon.sh

enum Brand {
    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static let background = dynamic(
        light: UIColor(red: 0.957, green: 0.937, blue: 0.902, alpha: 1), // #f4efe6 stage cream
        dark: UIColor(red: 0.039, green: 0.051, blue: 0.071, alpha: 1)  // #0a0d12 icon ring
    )
    static let card = dynamic(
        light: UIColor.white,
        dark: UIColor(red: 0.110, green: 0.094, blue: 0.086, alpha: 1)
    )
    static let cardElevated = dynamic(
        light: UIColor(red: 0.918, green: 0.867, blue: 0.788, alpha: 1), // #eaddc9 ghost slots
        dark: UIColor(red: 0.165, green: 0.141, blue: 0.125, alpha: 1)
    )

    /// Terracotta accent — WCAG AA on white text at 4.5:1+ (#c15c38).
    static let accent = Color(red: 0.757, green: 0.361, blue: 0.220)
    static let accentSecondary = Color(red: 0.925, green: 0.784, blue: 0.612) // #ecc89c warm sand
    static let accentWarm = Color(red: 0.831, green: 0.451, blue: 0.267)       // #d47344 lighter terracotta

    static let textPrimary = dynamic(
        light: UIColor(red: 0.173, green: 0.133, blue: 0.110, alpha: 1),
        dark: UIColor.white
    )
    static let textSecondary = dynamic(
        light: UIColor(red: 0.420, green: 0.365, blue: 0.329, alpha: 1),
        dark: UIColor(white: 1, alpha: 0.62)
    )
    static let textOnAccent = Color.white

    static let gradientTop = Color(red: 0.925, green: 0.784, blue: 0.612)   // warm sand
    static let gradientMid = Color(red: 0.824, green: 0.588, blue: 0.431)
    static let gradientBottom = Color(red: 0.757, green: 0.361, blue: 0.220)  // terracotta
}

// MARK: - Design system spacing

enum DS {
    enum Spacing {
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s5: CGFloat = 20
        static let s6: CGFloat = 24
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let pill: CGFloat = 999
    }
}

// MARK: - Chrome modifiers

struct BrandBackground: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .background {
                Group {
                    if reduceMotion {
                        Brand.background
                    } else {
                        LinearGradient(
                            colors: [Brand.gradientTop, Brand.gradientMid, Brand.gradientBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.35)
                        .background(Brand.background)
                    }
                }
                .ignoresSafeArea(edges: [.horizontal, .bottom])
            }
    }
}

struct BrandPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Brand.textOnAccent)
            .padding(.horizontal, DS.Spacing.s5)
            .padding(.vertical, DS.Spacing.s3)
            .background(Brand.accent.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(Capsule())
    }
}

struct BrandSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Brand.accent)
            .padding(.horizontal, DS.Spacing.s5)
            .padding(.vertical, DS.Spacing.s3)
            .background(Brand.cardElevated.opacity(configuration.isPressed ? 0.85 : 1))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Brand.accent.opacity(0.35), lineWidth: 1)
            )
    }
}

struct BrandScreenChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background {
                Brand.background
                    .ignoresSafeArea(edges: [.horizontal, .bottom])
            }
    }
}

extension View {
    func brandBackground() -> some View {
        modifier(BrandBackground())
    }

    func brandScreenChrome() -> some View {
        modifier(BrandScreenChrome())
    }

    func optionalAccessibilityIdentifier(_ identifier: String?) -> some View {
        modifier(OptionalAccessibilityIdentifier(identifier: identifier))
    }
}

struct OptionalAccessibilityIdentifier: ViewModifier {
    let identifier: String?

    func body(content: Content) -> some View {
        if let identifier, !identifier.isEmpty {
            content.accessibilityIdentifier(identifier)
        } else {
            content
        }
    }
}

// MARK: - Accessibility identifiers

enum A11yID {
    static let splashScreen = "splash_screen"
    static let splashLoading = "splash_loading"
    static let puzzleList = "puzzle_list"
    static let puzzleListStatusFilter = "puzzle_list_status_filter"
    static let puzzleListEmptyState = "puzzle_list_empty_state"
    static let puzzleListSearchField = "puzzle_list_search_field"
    static let puzzleListSortMenu = "puzzle_list_sort_menu"
    static let puzzleListResultCount = "puzzle_list_result_count"
    static let puzzleListMissingPiecesFilter = "puzzle_list_missing_pieces_filter"
    static let puzzleListNeedsPhotoFilter = "puzzle_list_needs_photo_filter"
    static let puzzleListPieceCountFilter = "puzzle_list_piece_count_filter"
    static let puzzleListTypeFilter = "puzzle_list_type_filter"
    static let puzzleListMaterialFilter = "puzzle_list_material_filter"
    static let puzzleListDispositionFilter = "puzzle_list_disposition_filter"
    static let puzzleListTagFilter = "puzzle_list_tag_filter"
    static let puzzleListClearFilters = "puzzle_list_clear_filters"
    static let addPuzzleButton = "add_puzzle_button"
    static let puzzleDetailSummary = "puzzle_detail_summary"
    static let puzzleDetailStats = "puzzle_detail_stats"
    static let puzzleDetailPaceRow = "puzzle_detail_pace_row"
    static let puzzleDetailHoursPer1000Row = "puzzle_detail_hours_per_1000_row"
    static let puzzleDetailProgress = "puzzle_detail_progress"
    static let puzzleDetailProgressSlider = "puzzle_detail_progress_slider"
    static let settingsRemoveDemoButton = "settings_remove_demo_button"
    static let settingsImportIPDbButton = "settings_import_ipdb_button"
    static let settingsImportBackupButton = "settings_import_backup_button"
    static let settingsRestoreBackupButton = "settings_restore_backup_button"
    static let settingsExportCollectionButton = "settings_export_collection_button"
    static let settingsBrandDisclaimerFooter = "settings_brand_disclaimer_footer"
    static let ipdbImportSummarySheet = "ipdb_import_summary_sheet"
    static let ipdbImportDoneButton = "ipdb_import_done_button"
    static let settingsTab = "settings_tab"
    static let puzzlesTab = "puzzles_tab"
    static let statsTab = "stats_tab"
    static let collectionStatsScreen = "collection_stats_screen"
    static let collectionStatsCompletedCard = "collection_stats_completed_card"
    static let collectionStatsPiecesCard = "collection_stats_pieces_card"
    static let collectionStatsBacklogCard = "collection_stats_backlog_card"
    static let collectionStatsTotalCard = "collection_stats_total_card"
    static let collectionStatsInProgressCard = "collection_stats_in_progress_card"
    static let collectionStatsMissingPiecesCard = "collection_stats_missing_pieces_card"
    static let collectionStatsWishlistCard = "collection_stats_wishlist_card"
    static let collectionStatsAbandonedCard = "collection_stats_abandoned_card"
    static let collectionStatsAverageDaysCard = "collection_stats_average_days_card"
    static let collectionStatsFavoriteTypeCard = "collection_stats_favorite_type_card"
    static let collectionStatsTopStoreCard = "collection_stats_top_store_card"
    static let collectionStatsMilestoneBanner = "collection_stats_milestone_banner"
    static let collectionStatsMilestoneDismiss = "collection_stats_milestone_dismiss"
    static let collectionStatsPickNextButton = "collection_stats_pick_next_button"
    static let collectionStatsRatingCard = "collection_stats_rating_card"
    static let collectionStatsFavoritePiecesCard = "collection_stats_favorite_pieces_card"
    static let collectionStatsHoursCard = "collection_stats_hours_card"
    static let collectionStatsMonthCard = "collection_stats_month_card"
    static let collectionStatsYearCard = "collection_stats_year_card"
    static let collectionStatsBiggestCard = "collection_stats_biggest_card"
    static let collectionStatsSmallestCard = "collection_stats_smallest_card"
    static let collectionStatsTopTagsCard = "collection_stats_top_tags_card"
    static let puzzleFormNameField = "puzzle_form_name_field"
    static let puzzleFormPiecesField = "puzzle_form_pieces_field"
    static let puzzleFormSourceField = "puzzle_form_source_field"
    static let puzzleFormPurchaseLocationField = "puzzle_form_purchase_location_field"
    static let puzzleFormStartDateField = "puzzle_form_start_date_field"
    static let puzzleFormBarcodeField = "puzzle_form_barcode_field"
    static let puzzleFormScanBarcodeButton = "puzzle_form_scan_barcode_button"
    static let puzzleFormRatingControl = "puzzle_form_rating_control"
    static let puzzleFormSubmitButton = "puzzle_form_submit_button"
    static let puzzleFormChoosePhotoButton = "puzzle_form_choose_photo_button"
    static let puzzleFormTakePhotoButton = "puzzle_form_take_photo_button"
    static let puzzleFormMissingPiecesToggle = "puzzle_form_missing_pieces_toggle"
    static let puzzleFormNotesField = "puzzle_form_notes_field"
    static let puzzleFormTagsField = "puzzle_form_tags_field"
    static let puzzleDetailEditButton = "puzzle_detail_edit_button"
    static let puzzleDetailRedoButton = "puzzle_detail_redo_button"
    static let puzzleDetailBarcodeRow = "puzzle_detail_barcode_row"
    static let onboardingSkipButton = "onboarding_skip_button"
    static let onboardingNextButton = "onboarding_next_button"
    static let onboardingBackButton = "onboarding_back_button"
    static let onboardingFinishButton = "onboarding_finish_button"

    static func puzzleRow(id: UUID) -> String {
        "puzzle_row_\(id.uuidString)"
    }

    static let scanBarcodeButton = "scan_barcode_button"
    static let barcodeScannerSheet = "barcode_scanner_sheet"
    static let barcodeScannerCancel = "barcode_scanner_cancel"
    static let quickAddPuzzleSheet = "quick_add_puzzle_sheet"
    static let quickAddSaveButton = "quick_add_save_button"
    static let quickAddSimilarSection = "quick_add_similar_section"
    static let shoppingModeSheet = "shopping_mode_sheet"
    static let shoppingModeCancel = "shopping_mode_cancel"
    static let shoppingModeMatchCard = "shopping_mode_match_card"
    static let shoppingModeNoMatchCard = "shopping_mode_no_match_card"
    static let shoppingModeOpenPuzzleButton = "shopping_mode_open_puzzle_button"
    static let shoppingModeAddPuzzleButton = "shopping_mode_add_puzzle_button"
    static let shoppingModeScanAnotherButton = "shopping_mode_scan_another_button"
    static let checkDuplicateButton = "check_duplicate_button"
    static let pickNextButton = "pick_next_button"
    static let pickNextScreen = "pick_next_screen"
    static let pickNextDoneButton = "pick_next_done_button"
    static let pickNextPieceFilter = "pick_next_piece_filter"
    static let pickNextTagFilter = "pick_next_tag_filter"
    static let pickNextPoolSummary = "pick_next_pool_summary"
    static let pickNextResultName = "pick_next_result_name"
    static let pickNextOpenButton = "pick_next_open_button"
    static let pickNextSpinButton = "pick_next_spin_button"
    static let puzzleCellRating = "puzzle_cell_rating"
    static let puzzleCellMissingPieces = "puzzle_cell_missing_pieces"
    static let puzzleCellProgress = "puzzle_cell_progress"
    static let puzzleShareButton = "puzzle_share_button"
}
