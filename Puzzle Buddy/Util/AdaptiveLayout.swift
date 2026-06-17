//
//  AdaptiveLayout.swift
//  Puzzle Buddy
//
//  Size-class and Dynamic Type helpers (MiniMuster / Dart Buddy pattern).
//

import SwiftUI

enum AdaptiveLayout {
    /// Prefer vertical stacking only at accessibility Dynamic Type sizes.
    /// Landscape uses compact vertical size class but has ample width for horizontal rows.
    static func usesStackedRowLayout(
        dynamicType: DynamicTypeSize,
        verticalSizeClass: UserInterfaceSizeClass? = nil
    ) -> Bool {
        dynamicType.isAccessibilitySize
    }

    /// Side-by-side hero + form on iPad or iPhone landscape.
    static func usesWideAuthLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> Bool {
        if horizontalSizeClass == .regular && verticalSizeClass != .compact {
            return true
        }
        return verticalSizeClass == .compact
    }

    /// Side-by-side summary + stats on iPad and iPhone landscape.
    static func usesWideDetailLayout(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass? = nil
    ) -> Bool {
        if horizontalSizeClass == .regular {
            return true
        }
        return verticalSizeClass == .compact
    }

    /// Max content width on iPad / regular width. Uses most of the available width with sensible caps.
    static func contentMaxWidth(
        containerWidth: CGFloat,
        verticalSizeClass: UserInterfaceSizeClass? = nil
    ) -> CGFloat {
        let minReadable: CGFloat = 680
        let maxReadable: CGFloat = verticalSizeClass == .compact ? 1_180 : 1_020
        let fraction: CGFloat = verticalSizeClass == .compact ? 0.94 : 0.96
        let target = containerWidth * fraction

        return min(max(target, minReadable), maxReadable, containerWidth)
    }

    /// Legacy helper for callers without geometry (previews, tests).
    static func contentMaxWidth(horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat? {
        horizontalSizeClass == .regular ? 1_020 : nil
    }

    /// Extra bottom inset so FAB and tab bar stay clear at large Dynamic Type.
    static func tabBarClearance(for dynamicType: DynamicTypeSize) -> CGFloat {
        if dynamicType >= .accessibility5 { return 220 }
        if dynamicType >= .accessibility3 { return 160 }
        if dynamicType.isAccessibilitySize { return 120 }
        return 88
    }
}

private struct AdaptiveScrollChrome: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    func body(content: Content) -> some View {
        if dynamicTypeSize.isAccessibilitySize || verticalSizeClass == .compact {
            scrollable(content)
        } else {
            content
        }
    }

    @ViewBuilder
    private func scrollable(_ content: Content) -> some View {
        let padded = content
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.bottom, AdaptiveLayout.tabBarClearance(for: dynamicTypeSize))

        if #available(iOS 16.4, *) {
            ScrollView { padded }
                .scrollBounceBehavior(.basedOnSize)
        } else {
            ScrollView { padded }
        }
    }
}

extension View {
    /// Scrollable chrome for login and compact-height layouts.
    func adaptiveScrollChrome() -> some View {
        modifier(AdaptiveScrollChrome())
    }

    /// Centers content in a readable column on iPad / regular width.
    func readableContentWidth() -> some View {
        modifier(ReadableContentWidth())
    }

    /// Readable column with full-bleed screen background (apply background after width constraint).
    func readableBrandScreenChrome() -> some View {
        readableContentWidth()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .brandScreenChrome()
    }

    /// Readable column with full-bleed brand background (apply background after width constraint).
    func readableBrandBackground() -> some View {
        readableContentWidth()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .brandBackground()
    }

    /// Card surface used across list rows and detail panels.
    func brandCardSurface() -> some View {
        background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
    }
}

private struct ReadableContentWidth: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular || verticalSizeClass == .compact {
            content
                .containerRelativeFrame(.horizontal) { length, _ in
                    AdaptiveLayout.contentMaxWidth(
                        containerWidth: length,
                        verticalSizeClass: verticalSizeClass
                    )
                }
                .frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}
