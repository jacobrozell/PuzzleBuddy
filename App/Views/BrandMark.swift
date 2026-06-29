//
//  BrandMark.swift
//  Puzzle Buddy
//

import SwiftUI

/// App mark — shared by launch screen, splash, onboarding, and settings.
struct BrandMark: View {
    var size: CGFloat = 160

    var body: some View {
        Image("LaunchCrestHero")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .shadow(color: .black.opacity(0.14), radius: size * 0.06, y: size * 0.03)
            .accessibilityLabel("\(AppInfo.displayName) icon")
    }
}

#Preview {
    ZStack {
        Color("LaunchBackground").ignoresSafeArea()
        BrandMark()
    }
}
