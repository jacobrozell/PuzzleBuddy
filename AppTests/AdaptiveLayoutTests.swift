//
//  AdaptiveLayoutTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class AdaptiveLayoutTests: XCTestCase {
    func testUsesWideDetailLayoutOnRegularWidth() {
        XCTAssertTrue(
            AdaptiveLayout.usesWideDetailLayout(
                horizontalSizeClass: .regular,
                verticalSizeClass: .regular
            )
        )
    }

    func testUsesWideDetailLayoutOnCompactHeight() {
        XCTAssertTrue(
            AdaptiveLayout.usesWideDetailLayout(
                horizontalSizeClass: .compact,
                verticalSizeClass: .compact
            )
        )
    }

    func testUsesStackedDetailLayoutOnCompactWidthPortrait() {
        XCTAssertFalse(
            AdaptiveLayout.usesWideDetailLayout(
                horizontalSizeClass: .compact,
                verticalSizeClass: .regular
            )
        )
    }

    func testContentMaxWidthUsesWiderCapInCompactHeight() {
        let portrait = AdaptiveLayout.contentMaxWidth(
            containerWidth: 1_200,
            verticalSizeClass: .regular
        )
        let compactHeight = AdaptiveLayout.contentMaxWidth(
            containerWidth: 1_200,
            verticalSizeClass: .compact
        )
        XCTAssertGreaterThan(compactHeight, portrait)
    }

    func testPresentsLongFormAsPageSizedAtRegularWidth() {
        XCTAssertTrue(
            AdaptiveLayout.presentsLongFormAsFullScreenCover(horizontalSizeClass: .regular)
        )
        XCTAssertFalse(
            AdaptiveLayout.presentsLongFormAsFullScreenCover(horizontalSizeClass: .compact)
        )
    }

    func testStatsGridColumnsUseAdaptiveLayoutAtRegularWidth() {
        let regular = AdaptiveLayout.statsGridColumns(horizontalSizeClass: .regular)
        XCTAssertEqual(regular.count, 1)
        XCTAssertEqual(regular[0].size, .adaptive(minimum: 220))

        let compact = AdaptiveLayout.statsGridColumns(horizontalSizeClass: .compact)
        XCTAssertEqual(compact.count, 2)
    }

    func testUsesLandscapePhoneLayoutOnCompactHeightOnly() {
        XCTAssertTrue(
            AdaptiveLayout.usesLandscapePhoneLayout(
                horizontalSizeClass: .compact,
                verticalSizeClass: .compact
            )
        )
        XCTAssertTrue(
            AdaptiveLayout.usesLandscapePhoneLayout(
                horizontalSizeClass: .regular,
                verticalSizeClass: .compact
            )
        )
        XCTAssertFalse(
            AdaptiveLayout.usesLandscapePhoneLayout(
                horizontalSizeClass: .compact,
                verticalSizeClass: .regular
            )
        )
        XCTAssertFalse(
            AdaptiveLayout.usesLandscapePhoneLayout(
                horizontalSizeClass: .regular,
                verticalSizeClass: .regular
            )
        )
    }

    func testUsesSplitNavigationAtRegularWidthRegardlessOfIdiom() {
        XCTAssertTrue(AdaptiveLayout.usesSplitNavigation(horizontalSizeClass: .regular))
        XCTAssertFalse(AdaptiveLayout.usesSplitNavigation(horizontalSizeClass: .compact))
    }
}
