//
//  BrandMark.swift
//  Puzzle Buddy
//

import SwiftUI

/// App mark — shared by launch screen, splash, onboarding, and settings.
struct BrandMark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var size: CGFloat = 160
    var animated: Bool = false

    private var cornerRadius: CGFloat { size * 0.22 }
    private var markShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        Group {
            if animated && !reduceMotion {
                AnimatedGIFView(resourceName: Self.loadingGIFResourceName, isAnimating: true)
                    .frame(width: size, height: size)
            } else {
                staticImage
                    .frame(width: size, height: size)
            }
        }
        .clipShape(markShape)
        .shadow(color: .black.opacity(0.14), radius: size * 0.06, y: size * 0.03)
        .accessibilityLabel("\(AppInfo.displayName) icon")
    }

    private var staticImage: some View {
        Image("LaunchCrestHero")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }

    static let loadingGIFResourceName = "splash_loading"
}

#Preview("Static") {
    ZStack {
        Color("LaunchBackground").ignoresSafeArea()
        BrandMark()
    }
}

#Preview("Animated") {
    ZStack {
        Color("LaunchBackground").ignoresSafeArea()
        BrandMark(size: 132, animated: true)
    }
}
