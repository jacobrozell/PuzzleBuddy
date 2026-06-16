//
//  DesignTokens.swift
//  Puzzle Buddy
//
//  Shared visual tokens aligned with Dart Buddy / MiniMuster-style polish.
//

import SwiftUI
import UIKit

// MARK: - Brand palette

enum Brand {
    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }

    static let background = dynamic(
        light: UIColor(red: 0.95, green: 0.97, blue: 0.98, alpha: 1),
        dark: UIColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 1)
    )
    static let card = dynamic(
        light: UIColor.white,
        dark: UIColor(red: 0.11, green: 0.12, blue: 0.14, alpha: 1)
    )
    static let cardElevated = dynamic(
        light: UIColor(red: 0.92, green: 0.95, blue: 0.97, alpha: 1),
        dark: UIColor(red: 0.16, green: 0.17, blue: 0.19, alpha: 1)
    )

    /// Puzzle Buddy signature teal accent (WCAG AA on white text at 4.5:1+).
    static let accent = Color(red: 0.05, green: 0.55, blue: 0.62)
    static let accentSecondary = Color(red: 0.12, green: 0.72, blue: 0.78)
    static let accentWarm = Color(red: 0.93, green: 0.45, blue: 0.13)

    static let textPrimary = dynamic(
        light: UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1),
        dark: UIColor.white
    )
    static let textSecondary = dynamic(
        light: UIColor(red: 0.35, green: 0.38, blue: 0.42, alpha: 1),
        dark: UIColor(white: 1, alpha: 0.62)
    )
    static let textOnAccent = Color.white

    static let gradientTop = Color(red: 0.10, green: 0.45, blue: 0.85)
    static let gradientMid = Color(red: 0.12, green: 0.68, blue: 0.82)
    static let gradientBottom = Color(red: 0.08, green: 0.58, blue: 0.55)
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
            .background(Brand.background)
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
    static let loginEmailField = "login_email_field"
    static let loginPasswordField = "login_password_field"
    static let passwordVisibilityToggle = "password_visibility_toggle"
    static let loginSubmitButton = "login_submit_button"
    static let forgotPasswordButton = "forgot_password_button"
    static let puzzleList = "puzzle_list"
    static let addPuzzleButton = "add_puzzle_button"
    static let puzzleDetailSummary = "puzzle_detail_summary"
    static let puzzleDetailStats = "puzzle_detail_stats"
    static let settingsSignOutButton = "settings_sign_out_button"
    static let settingsTab = "settings_tab"
    static let puzzlesTab = "puzzles_tab"
    static let puzzleFormNameField = "puzzle_form_name_field"
    static let puzzleFormPiecesField = "puzzle_form_pieces_field"
    static let puzzleFormSubmitButton = "puzzle_form_submit_button"
    static let puzzleFormChoosePhotoButton = "puzzle_form_choose_photo_button"
    static let puzzleFormTakePhotoButton = "puzzle_form_take_photo_button"
    static let puzzleDetailEditButton = "puzzle_detail_edit_button"

    static func puzzleRow(id: UUID) -> String {
        "puzzle_row_\(id.uuidString)"
    }
}
