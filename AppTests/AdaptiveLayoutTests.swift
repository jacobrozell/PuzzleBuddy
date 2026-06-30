//
//  AdaptiveLayoutTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class AdaptiveLayoutTests: XCTestCase {
    func testUsesWideDetailLayoutOnIPad() {
        XCTAssertTrue(
            AdaptiveLayout.usesWideDetailLayout(
                horizontalSizeClass: .regular,
                verticalSizeClass: .regular
            )
        )
    }

    func testUsesWideDetailLayoutOnIPhoneLandscape() {
        XCTAssertTrue(
            AdaptiveLayout.usesWideDetailLayout(
                horizontalSizeClass: .compact,
                verticalSizeClass: .compact
            )
        )
    }

    func testUsesStackedDetailLayoutOnIPhonePortrait() {
        XCTAssertFalse(
            AdaptiveLayout.usesWideDetailLayout(
                horizontalSizeClass: .compact,
                verticalSizeClass: .regular
            )
        )
    }

    func testContentMaxWidthUsesWiderCapInLandscape() {
        let portrait = AdaptiveLayout.contentMaxWidth(
            containerWidth: 1_200,
            verticalSizeClass: .regular
        )
        let landscape = AdaptiveLayout.contentMaxWidth(
            containerWidth: 1_200,
            verticalSizeClass: .compact
        )
        XCTAssertGreaterThan(landscape, portrait)
    }

    func testPresentsLongFormAsFullScreenCoverOnIPad() {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCTAssertTrue(
                AdaptiveLayout.presentsLongFormAsFullScreenCover(horizontalSizeClass: .regular)
            )
        } else {
            XCTAssertFalse(
                AdaptiveLayout.presentsLongFormAsFullScreenCover(horizontalSizeClass: .regular)
            )
        }
        #endif
        XCTAssertFalse(
            AdaptiveLayout.presentsLongFormAsFullScreenCover(horizontalSizeClass: .compact)
        )
    }

    func testStatsGridColumnsUseAdaptiveLayoutOnIPad() {
        let iPad = AdaptiveLayout.statsGridColumns(horizontalSizeClass: .regular)
        XCTAssertEqual(iPad.count, 1)
        XCTAssertEqual(iPad[0].size, .adaptive(minimum: 220))

        let iPhone = AdaptiveLayout.statsGridColumns(horizontalSizeClass: .compact)
        XCTAssertEqual(iPhone.count, 2)
    }

    func testUsesLandscapePhoneLayoutOnCompactHeight() {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCTAssertTrue(
                AdaptiveLayout.usesLandscapePhoneLayout(
                    horizontalSizeClass: .compact,
                    verticalSizeClass: .compact
                )
            )
            XCTAssertFalse(
                AdaptiveLayout.usesLandscapePhoneLayout(
                    horizontalSizeClass: .compact,
                    verticalSizeClass: .regular
                )
            )
        } else {
            XCTAssertFalse(
                AdaptiveLayout.usesLandscapePhoneLayout(
                    horizontalSizeClass: .regular,
                    verticalSizeClass: .compact
                )
            )
        }
        #endif
    }

    func testUsesSplitNavigationOnIPad() {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCTAssertTrue(AdaptiveLayout.usesSplitNavigation(horizontalSizeClass: .regular))
        } else {
            XCTAssertFalse(AdaptiveLayout.usesSplitNavigation(horizontalSizeClass: .regular))
        }
        #endif
        XCTAssertFalse(AdaptiveLayout.usesSplitNavigation(horizontalSizeClass: .compact))
    }
}
