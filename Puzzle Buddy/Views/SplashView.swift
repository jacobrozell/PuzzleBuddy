//
//  SplashView.swift
//  Puzzle Buddy
//

import SwiftUI

/// Branded splash shown immediately after the system launch screen.
struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showLoading = false
    @State private var pulse = false

    @ScaledMetric(relativeTo: .largeTitle) private var crestDiameter: CGFloat = 132

    var body: some View {
        ZStack {
            splashBackground

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                crestHero
                    .padding(.bottom, 28)

                branding
                    .padding(.bottom, 36)

                loadingSection
                    .opacity(showLoading ? 1 : 0)
                    .offset(y: showLoading ? 0 : 8)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 48)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(A11yID.splashScreen)
        .onAppear {
            pulse = !reduceMotion
            if reduceMotion {
                showLoading = true
            } else {
                withAnimation(.easeOut(duration: 0.35)) {
                    showLoading = true
                }
            }
        }
    }

    private var splashBackground: some View {
        ZStack {
            Brand.background
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Brand.accentSecondary.opacity(0.22),
                    Brand.background.opacity(0),
                ],
                center: .top,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Brand.gradientTop.opacity(0.12),
                    Brand.background.opacity(0),
                ],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 320
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Brand.background.opacity(0),
                    Brand.cardElevated.opacity(0.55),
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var crestHero: some View {
        ZStack {
            Circle()
                .fill(Brand.accent.opacity(0.12))
                .frame(width: crestDiameter, height: crestDiameter)
                .scaleEffect(pulse ? 1.06 : 0.94)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                    value: pulse
                )

            Circle()
                .strokeBorder(Brand.accent.opacity(0.35), lineWidth: 1.5)
                .frame(width: crestDiameter, height: crestDiameter)

            Circle()
                .strokeBorder(Brand.accent.opacity(0.12), lineWidth: 8)
                .frame(width: crestDiameter * 1.18, height: crestDiameter * 1.18)

            BrandMark(size: crestDiameter, animated: true)
        }
        .accessibilityLabel(AppInfo.displayName)
    }

    private var branding: some View {
        VStack(spacing: 10) {
            Text(AppInfo.displayName)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Brand.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("Log · Track · Complete")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.accent)
                .tracking(0.6)
                .multilineTextAlignment(.center)

            Text("Your puzzle collection companion")
                .font(.footnote)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
                .tint(Brand.accent)
                .accessibilityIdentifier(A11yID.splashLoading)

            Text("Piecing things together…")
                .font(.caption.weight(.medium))
                .foregroundStyle(Brand.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(Brand.accent.opacity(0.25), lineWidth: 0.5)
        }
    }
}

#Preview("Light") {
    SplashView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SplashView()
        .preferredColorScheme(.dark)
}
