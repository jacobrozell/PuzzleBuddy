//
//  BarcodeNormalizerTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class BarcodeNormalizerTests: XCTestCase {
    func testNormalizeStripsNonDigits() {
        XCTAssertEqual(BarcodeNormalizer.normalize("0123-4567-8905"), "012345678905")
    }

    func testNormalizeRejectsTooShort() {
        XCTAssertNil(BarcodeNormalizer.normalize("12345"))
    }

    func testNormalizeAcceptsCommonLengths() {
        XCTAssertEqual(BarcodeNormalizer.normalize("12345678")?.count, 8)
        XCTAssertEqual(BarcodeNormalizer.normalize("012345678905")?.count, 12)
        XCTAssertEqual(BarcodeNormalizer.normalize("4006381333931")?.count, 13)
    }

    func testNormalizeEmptyReturnsNil() {
        XCTAssertNil(BarcodeNormalizer.normalize(""))
        XCTAssertNil(BarcodeNormalizer.normalize(nil))
    }

    func testNormalizeRejectsFifteenPlusDigits() {
        XCTAssertNil(BarcodeNormalizer.normalize(String(repeating: "1", count: 15)))
    }

    func testOptionalDigitsExtractsWithoutLengthValidation() {
        XCTAssertEqual(
            BarcodeNormalizer.optionalDigits(from: String(repeating: "9", count: 20))?.count,
            20
        )
    }
}
