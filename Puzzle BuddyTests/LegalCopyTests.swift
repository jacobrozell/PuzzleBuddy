//
//  LegalCopyTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class LegalCopyTests: XCTestCase {
    func testBrandDisclaimerMentionsTrademarksAndNonAffiliation() {
        XCTAssertTrue(LegalCopy.brandTrademarkDisclaimer.localizedCaseInsensitiveContains("trademark"))
        XCTAssertTrue(LegalCopy.brandTrademarkDisclaimer.localizedCaseInsensitiveContains("not affiliated"))
    }

    func testIPDbDisclaimerMentionsNonAffiliation() {
        XCTAssertTrue(LegalCopy.ipdbImportDisclaimer.localizedCaseInsensitiveContains("not affiliated with IPDb"))
    }

    func testBarcodeScanDisclaimerMentionsReviewBeforeSaving() {
        XCTAssertTrue(LegalCopy.barcodeScanDisclaimer.localizedCaseInsensitiveContains("starting point"))
        XCTAssertTrue(LegalCopy.barcodeScanDisclaimer.localizedCaseInsensitiveContains("review"))
    }
}
