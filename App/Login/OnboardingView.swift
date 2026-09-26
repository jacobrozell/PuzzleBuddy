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
        // First-run users already saw 1.1 features in onboarding — skip the upgrader sheet.
        WhatsNewPrompt.markSeen()
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.removeObject(forKey: legacyKey)
    }
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pageIndex = MarketingSnapshotBootstrap.initialOnboardingPage

    private let pages: [OnboardingPage] = {
        let heroes: [OnboardingHeroStyle] = [
            .brandMark,
            .scene(.barcode),
            .scene(.collection),
            .scene(.ready),
        ]
        return zip(OnboardingCopy.pages(), heroes).map { copy, hero in
            OnboardingPage(title: copy.title, message: copy.message, hero: hero)
        }
    }()

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $pageIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .accessibilityLabel("Onboarding")
            .accessibilityValue("Page \(pageIndex + 1) of \(pages.count)")
            .accessibilityIdentifier(A11yID.onboardingPager)

            pageIndicator
                .padding(.bottom, verticalSizeClass == .compact ? DS.Spacing.s2 : DS.Spacing.s3)

            onboardingFooter
        }
        .readableBrandBackground(ignoresSafeAreaEdges: .all)
    }

    private var pageIndicator: some View {
        HStack(spacing: DS.Spacing.s2) {
            ForEach(0 ..< pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == pageIndex ? Brand.accent : Brand.accent.opacity(0.28))
                    .frame(width: index == pageIndex ? 22 : 8, height: 8)
                    .accessibilityHidden(true)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: pageIndex)
        .accessibilityHidden(true)
    }

    private var onboardingFooter: some View {
        VStack(spacing: DS.Spacing.s3) {
            Rectangle()
                .fill(Brand.accent.opacity(0.12))
                .frame(height: 1)
                .padding(.horizontal, DS.Spacing.s5)

            HStack(spacing: DS.Spacing.s2) {
                if pageIndex > 0 {
                    Button("Back") {
                        advance(by: -1)
                    }
                    .buttonStyle(BrandSecondaryButtonStyle(compact: true))
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
                .buttonStyle(BrandSecondaryButtonStyle(compact: true))
                .accessibilityIdentifier(A11yID.onboardingSkipButton)
                .accessibilityLabel("Skip onboarding")

                Spacer(minLength: DS.Spacing.s2)

                Button(pageIndex == pages.count - 1 ? "Get Started" : "Next") {
                    if pageIndex == pages.count - 1 {
                        completeOnboarding()
                    } else {
                        advance(by: 1)
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .accessibilityIdentifier(
                    pageIndex == pages.count - 1 ? A11yID.onboardingFinishButton : A11yID.onboardingNextButton
                )
                .accessibilityLabel(
                    pageIndex == pages.count - 1 ? "Get started with Puzzle Buddy" : "Next onboarding page"
                )
            }
            .padding(.horizontal, DS.Spacing.s5)
            .padding(.bottom, verticalSizeClass == .compact ? DS.Spacing.s2 : DS.Spacing.s4)
        }
    }

    private func advance(by delta: Int) {
        let next = pageIndex + delta
        guard pages.indices.contains(next) else { return }
        if reduceMotion {
            pageIndex = next
        } else {
            withAnimation(.easeInOut(duration: 0.28)) {
                pageIndex = next
            }
        }
    }

    private func completeOnboarding(logCompletedEvent: Bool = true) {
        OnboardingStorage.markComplete()
        isPresented = false
        AnalyticsUserContext.syncOnboardingComplete(true)
        if logCompletedEvent {
            AppLog.shared.info(.app, eventName: "onboarding_completed", message: "Onboarding finished.")
        }
    }
}

private enum OnboardingHeroStyle {
    case brandMark
    case scene(OnboardingScene)
}

private enum OnboardingScene {
    case barcode
    case collection
    case ready

    var symbolName: String {
        switch self {
        case .barcode: return "barcode.viewfinder"
        case .collection: return "list.bullet"
        case .ready: return "puzzlepiece.extension.fill"
        }
    }

    var symbolOffset: CGSize {
        switch self {
        case .ready: return CGSize(width: -3, height: 0)
        case .barcode, .collection: return .zero
        }
    }

    var accentWarmth: Double {
        switch self {
        case .barcode: return 0.18
        case .collection: return 0.12
        case .ready: return 0.22
        }
    }
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let hero: OnboardingHeroStyle
}

private struct OnboardingPageView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let page: OnboardingPage

    @State private var contentVisible = false

    private var isCompactHeight: Bool { verticalSizeClass == .compact }
    private var heroFrame: CGFloat { isCompactHeight ? 112 : 200 }
    private var brandMarkSize: CGFloat { isCompactHeight ? 72 : 120 }

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
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : (reduceMotion ? 0 : 14))
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear { revealContent() }
    }

    @ViewBuilder
    private var hero: some View {
        switch page.hero {
        case .brandMark:
            PuzzleHeroView(size: brandMarkSize)
        case .scene(let scene):
            OnboardingSceneHero(scene: scene, size: heroFrame * 0.72)
        }
    }

    private func revealContent() {
        if reduceMotion {
            contentVisible = true
            return
        }
        contentVisible = false
        withAnimation(.easeOut(duration: 0.42)) {
            contentVisible = true
        }
    }
}

/// Soft ambient scene behind a themed SF Symbol — keeps onboarding on-brand without custom art assets.
private struct OnboardingSceneHero: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let scene: OnboardingScene
    var size: CGFloat

    @State private var pulse = false

    private var iconSize: CGFloat { size * 0.34 }
    private var containerSize: CGFloat { size * 0.58 }

    var body: some View {
        ZStack {
            Circle()
                .fill(Brand.accent.opacity(0.10))
                .frame(width: size * 1.12, height: size * 1.12)
                .scaleEffect(pulse ? 1.05 : 0.94)

            Circle()
                .strokeBorder(Brand.accent.opacity(0.22), lineWidth: 1.5)
                .frame(width: size, height: size)
                .scaleEffect(pulse ? 1.02 : 0.98)

            Circle()
                .fill(Brand.accentWarm.opacity(scene.accentWarmth * 0.35))
                .frame(width: size * 0.42, height: size * 0.42)
                .offset(x: size * 0.28, y: -size * 0.22)
                .blur(radius: 2)

            RoundedRectangle(cornerRadius: containerSize * 0.24, style: .continuous)
                .fill(Brand.card.opacity(0.72))
                .frame(width: containerSize, height: containerSize)
                .overlay {
                    RoundedRectangle(cornerRadius: containerSize * 0.24, style: .continuous)
                        .strokeBorder(Brand.accent.opacity(0.18), lineWidth: 1)
                }
                .shadow(color: Brand.accent.opacity(0.12), radius: size * 0.06, y: size * 0.03)

            Image(systemName: scene.symbolName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(Brand.accent)
                .symbolRenderingMode(.monochrome)
                .offset(scene.symbolOffset)
                .scaleEffect(pulse ? 1.04 : 0.96)
        }
        .frame(width: size * 1.2, height: size * 1.2)
        .onAppear {
            guard !reduceMotion else { return }
            pulse = true
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
            value: pulse
        )
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
