//
//  OnboardingView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 5/11/23.
//

import SwiftUI

enum OnboardingStorage {
    private static let key = "PuzzleBuddy.OnboardingComplete"
    private static let legacyKey = "PuzzlePal_Onboarding_Complete"

    static var isComplete: Bool {
        if ProcessInfo.processInfo.environment["UI_TESTING_BYPASS_AUTH"] == "1" { return true }
        if ProcessInfo.processInfo.arguments.contains(UITestSupport.bypassAuth) { return true }
        if UITestSupport.isRunningUnderTest { return true }
        return UserDefaults.standard.bool(forKey: key)
            || UserDefaults.standard.bool(forKey: legacyKey)
    }

    static func markComplete() {
        UserDefaults.standard.set(true, forKey: key)
    }
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var pageIndex = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to \(Config.appName)",
            message: "Your personal jigsaw puzzle catalog — track every box on your shelf, offline and private.",
            hero: .brandMark
        ),
        OnboardingPage(
            title: "Shop With Confidence",
            message: "Scan a barcode at the thrift store to check duplicates instantly — no account or internet required.",
            hero: .systemImage("barcode.viewfinder")
        ),
        OnboardingPage(
            title: "Build Your Collection",
            message: "Log brands, piece counts, progress, and ratings. Import from an IPDb CSV export in Settings when you're ready.",
            hero: .systemImage("list.bullet.rectangle.fill")
        ),
        OnboardingPage(
            title: "Ready to Puzzle?",
            message: "Everything stays on your device. Add your first puzzle or import a collection to get started.",
            hero: .systemImage("puzzlepiece.extension.fill")
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .accessibilityLabel("Onboarding")
            .accessibilityValue("Page \(pageIndex + 1) of \(pages.count)")

            onboardingFooter
        }
        .readableBrandBackground()
    }

    private var onboardingFooter: some View {
        HStack {
            if pageIndex > 0 {
                Button("Back") {
                    withAnimation { pageIndex -= 1 }
                }
                .buttonStyle(BrandSecondaryButtonStyle())
                .accessibilityIdentifier(A11yID.onboardingBackButton)
                .accessibilityLabel("Previous onboarding page")
            } else {
                Button("Skip") {
                    completeOnboarding()
                }
                .buttonStyle(BrandSecondaryButtonStyle())
                .accessibilityIdentifier(A11yID.onboardingSkipButton)
                .accessibilityLabel("Skip onboarding")
            }

            Spacer()

            Button(pageIndex == pages.count - 1 ? "Get Started" : "Next") {
                if pageIndex == pages.count - 1 {
                    completeOnboarding()
                } else {
                    withAnimation { pageIndex += 1 }
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle())
            .accessibilityIdentifier(
                pageIndex == pages.count - 1 ? A11yID.onboardingFinishButton : A11yID.onboardingNextButton
            )
            .accessibilityLabel(pageIndex == pages.count - 1 ? "Get started with Puzzle Buddy" : "Next onboarding page")
        }
        .padding(.horizontal, DS.Spacing.s5)
        .padding(.vertical, DS.Spacing.s4)
    }

    private func completeOnboarding() {
        OnboardingStorage.markComplete()
        isPresented = false
        AppLog.shared.info(.app, eventName: "onboarding_completed", message: "Onboarding finished.")
    }
}

private enum OnboardingHeroStyle {
    case brandMark
    case systemImage(String)
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let hero: OnboardingHeroStyle
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: DS.Spacing.s5) {
            Spacer()

            hero
                .frame(maxWidth: 180, maxHeight: 180)
                .accessibilityHidden(true)

            VStack(spacing: DS.Spacing.s3) {
                Text(page.title)
                    .font(.title2.bold())
                    .foregroundStyle(Brand.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.message)
                    .font(.body)
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, DS.Spacing.s6)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer()
            Spacer()
        }
        .padding(.top, DS.Spacing.s6)
    }

    @ViewBuilder
    private var hero: some View {
        switch page.hero {
        case .brandMark:
            PuzzleHeroView(size: 120)
        case .systemImage(let name):
            Image(systemName: name)
                .font(.system(size: 72))
                .foregroundStyle(Brand.accent)
                .symbolRenderingMode(.hierarchical)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Brand.card.opacity(0.6), in: Circle())
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
