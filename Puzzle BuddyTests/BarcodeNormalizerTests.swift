//
//  BarcodeNormalizerTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

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
}
