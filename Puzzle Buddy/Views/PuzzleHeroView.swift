//
//  PuzzleHeroView.swift
//  Puzzle Buddy
//

import SwiftUI

/// Decorative branded puzzle mark with a gentle breathing animation.
struct PuzzleHeroView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var size: CGFloat = 100

    var body: some View {
        ZStack {
            Circle()
                .fill(Brand.accent.opacity(0.1))
                .frame(width: size * 1.2, height: size * 1.2)
                .scaleEffect(animate ? 1.06 : 0.94)

            Circle()
                .strokeBorder(Brand.accent.opacity(0.25), lineWidth: 1)
                .frame(width: size * 1.2, height: size * 1.2)

            BrandMark(size: size)
                .rotationEffect(.degrees(animate ? 2 : -2))
                .scaleEffect(animate ? 1.03 : 0.97)
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
            value: animate
        )
        .onAppear {
            animate = !reduceMotion
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Brand.background.ignoresSafeArea()
        PuzzleHeroView(size: 120)
    }
}
