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
        if MarketingSnapshotBootstrap.shouldShowOnboarding { return false }
        if UITestSupport.isBypassOnboardingEnabled { return true }
        if UITestSupport.isRunningUnderTest { return true }
        return UserDefaults.standard.bool(forKey: key)
            || UserDefaults.standard.bool(forKey: legacyKey)
    }

    static func markComplete() {
        UserDefaults.standard.set(true, forKey: key)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var pageIndex = MarketingSnapshotBootstrap.initialOnboardingPage

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to \(AppInfo.displayName)",
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
            message: "Log brands, piece counts, tags, ratings, and progress. Spin the dice to pick your next puzzle from the backlog.",
            hero: .systemImage("list.bullet.rectangle.fill")
        ),
        OnboardingPage(
            title: "Ready to Puzzle?",
            message: "Everything stays on your device. Add your first puzzle and start tracking.",
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
        .readableBrandBackground(ignoresSafeAreaEdges: .all)
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
            }

            Button("Skip") {
                AppLog.shared.info(
                    .app,
                    eventName: "onboarding_skipped",
                    message: "Onboarding skipped.",
                    metadata: ["page_index": "\(pageIndex)"]
                )
                completeOnboarding(logCompletedEvent: false)
            }
            .buttonStyle(BrandSecondaryButtonStyle())
            .accessibilityIdentifier(A11yID.onboardingSkipButton)
            .accessibilityLabel("Skip onboarding")

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
        .padding(.vertical, verticalSizeClass == .compact ? DS.Spacing.s2 : DS.Spacing.s4)
    }

    private func completeOnboarding(logCompletedEvent: Bool = true) {
        OnboardingStorage.markComplete()
        isPresented = false
        if logCompletedEvent {
            AppLog.shared.info(.app, eventName: "onboarding_completed", message: "Onboarding finished.")
        }
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
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let page: OnboardingPage

    private var isCompactHeight: Bool { verticalSizeClass == .compact }
    private var heroFrame: CGFloat { isCompactHeight ? 100 : 180 }
    private var brandMarkSize: CGFloat { isCompactHeight ? 72 : 120 }
    private var systemIconSize: CGFloat { isCompactHeight ? 48 : 72 }

    var body: some View {
        ScrollView {
            VStack(spacing: isCompactHeight ? DS.Spacing.s3 : DS.Spacing.s5) {
                if !isCompactHeight {
                    Spacer(minLength: DS.Spacing.s4)
                }

                hero
                    .frame(maxWidth: heroFrame, maxHeight: heroFrame)
                    .accessibilityHidden(true)

                VStack(spacing: DS.Spacing.s3) {
                    Text(page.title)
                        .font(isCompactHeight ? .title3.bold() : .title2.bold())
                        .foregroundStyle(Brand.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(page.message)
                        .font(isCompactHeight ? .subheadline : .body)
                        .foregroundStyle(Brand.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, isCompactHeight ? DS.Spacing.s4 : DS.Spacing.s6)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                if !isCompactHeight {
                    Spacer()
                    Spacer()
                }
            }
            .padding(.top, isCompactHeight ? DS.Spacing.s3 : DS.Spacing.s6)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    @ViewBuilder
    private var hero: some View {
        switch page.hero {
        case .brandMark:
            PuzzleHeroView(size: brandMarkSize)
        case .systemImage(let name):
            Image(systemName: name)
                .font(.system(size: systemIconSize))
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
