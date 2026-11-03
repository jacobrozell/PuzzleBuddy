//
//  SystemNavigationPolicy.swift
//  Puzzle Buddy
//
//  iOS 26+ Liquid Glass nav + window fill so iPhone Duo has no white edge gaps.
//

import SwiftUI
import UIKit

enum SystemNavigationPolicy {
    /// When true, system tab bars and navigation toolbars use Liquid Glass; do not
    /// override with opaque toolbar backgrounds (those leave a white strip on Duo).
    static var usesSystemLiquidGlassNav: Bool {
        if #available(iOS 26, *) { return true }
        return false
    }
}

extension View {
    /// Opaque nav fill on iOS 18–25; Liquid Glass on iOS 26+ with brand content behind it.
    @ViewBuilder
    func brandNavigationBarBackground(_ color: Color = Brand.background) -> some View {
        if SystemNavigationPolicy.usesSystemLiquidGlassNav {
            self.containerBackground(color, for: .navigation)
        } else {
            self
                .toolbarBackground(color, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    /// Paints the UIWindow with `Brand.background` so uncovered Duo edges are not white.
    func brandWindowBackground() -> some View {
        background(BrandWindowBackground())
    }
}

private struct BrandWindowBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> WindowBackgroundView {
        WindowBackgroundView()
    }

    func updateUIView(_ uiView: WindowBackgroundView, context: Context) {
        uiView.applyBrandBackground()
    }
}

private final class WindowBackgroundView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        applyBrandBackground()
    }

    func applyBrandBackground() {
        backgroundColor = .clear
        let color = Brand.backgroundUIColor
        window?.backgroundColor = color
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for sceneWindow in windowScene.windows {
                sceneWindow.backgroundColor = color
                sceneWindow.rootViewController?.view.backgroundColor = color
            }
        }
    }
}
