//
//  PurchasePriceFormattingTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class PurchasePriceFormattingTests: XCTestCase {
    func testParseAcceptsDecimalString() {
        XCTAssertEqual(PurchasePriceFormatting.parse("12.99"), 12.99)
        XCTAssertEqual(PurchasePriceFormatting.parse("$14.50"), 14.50)
    }

    func testParseEmptyReturnsNil() {
        XCTAssertNil(PurchasePriceFormatting.parse(""))
        XCTAssertNil(PurchasePriceFormatting.parse("   "))
    }

    func testParseClampsMaximum() {
        XCTAssertEqual(PurchasePriceFormatting.parse("9999999"), 999_999.99)
    }

    func testParseRejectsNegative() {
        XCTAssertNil(PurchasePriceFormatting.parse("-5"))
    }

    func testDisplayLabelFormatsUSD() {
        let label = PurchasePriceFormatting.displayLabel(price: 12.5, currencyCode: "USD")
        XCTAssertTrue(label.contains("12.5") || label.contains("12.50"))
        XCTAssertTrue(label.contains("$") || label.contains("US"))
    }
}
