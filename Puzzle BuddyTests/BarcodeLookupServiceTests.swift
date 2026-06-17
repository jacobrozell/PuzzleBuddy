//
//  BarcodeLookupServiceTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class BarcodeLookupServiceTests: XCTestCase {
    func testParseResponseExtractsMetadata() throws {
        let json = """
        {
          "items": [{
            "title": "Galison Winter Lights 1000 Piece Puzzle",
            "brand": "Galison",
            "images": ["https://example.com/box.jpg"]
          }]
        }
        """.data(using: .utf8)!

        let metadata = try XCTUnwrap(BarcodeLookupService.parseResponse(json))
        XCTAssertEqual(metadata.suggestedName, "Galison Winter Lights 1000 Piece Puzzle")
        XCTAssertEqual(metadata.brand, "Galison")
        XCTAssertEqual(metadata.suggestedPieces, 1000)
        XCTAssertEqual(metadata.imageURL?.absoluteString, "https://example.com/box.jpg")
    }

    func testParseResponseReturnsNilForEmptyItems() throws {
        let json = #"{"items":[]}"#.data(using: .utf8)!
        XCTAssertNil(try BarcodeLookupService.parseResponse(json))
    }
}
