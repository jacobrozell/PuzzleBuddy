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
}
