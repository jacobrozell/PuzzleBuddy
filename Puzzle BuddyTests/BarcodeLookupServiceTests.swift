//
//  BarcodeLookupServiceTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class BarcodeLookupServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        BarcodeLookupService.resetCacheForTesting()
        BarcodeMetadataCache.resetForTesting()
    }

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
        XCTAssertEqual(metadata.source, "upcitemdb")
    }

    func testParseResponseReturnsNilForEmptyItems() throws {
        let json = #"{"items":[]}"#.data(using: .utf8)!
        XCTAssertNil(try BarcodeLookupService.parseResponse(json))
    }

    func testNoticeMapsRateLimitStatus() {
        XCTAssertEqual(BarcodeLookupResult.notice(forHTTPStatusCode: 429), .rateLimited)
    }

    func testNoticeMapsServerErrors() {
        XCTAssertEqual(BarcodeLookupResult.notice(forHTTPStatusCode: 500), .unavailable)
        XCTAssertEqual(BarcodeLookupResult.notice(forHTTPStatusCode: 403), .unavailable)
    }

    func testNoticeReturnsNilForSuccessStatus() {
        XCTAssertNil(BarcodeLookupResult.notice(forHTTPStatusCode: 200))
    }

    func testLookupUsesLocalCacheBeforeNetwork() async {
        var puzzle = Puzzle.fixture(name: "Cached Harbor", pieces: 500)
        puzzle.barcode = "012345678905"
        puzzle.source = "Galison"
        BarcodeMetadataCache.store(from: puzzle)

        let result = await BarcodeLookupService.lookup(barcode: "012345678905")
        XCTAssertEqual(result.metadata?.suggestedName, "Cached Harbor")
        XCTAssertEqual(result.metadata?.brand, "Galison")
        XCTAssertEqual(result.metadata?.source, "local_cache")
        XCTAssertNil(result.notice)
    }

    func testLookupSkipsNetworkWhenToggleWouldBeOff() async {
        UserDefaults.standard.set(false, forKey: UserPreferences.barcodeLookupStorageKey)
        defer { UserDefaults.standard.removeObject(forKey: UserPreferences.barcodeLookupStorageKey) }

        let result = await BarcodeLookupService.lookup(barcode: "999999999999")
        XCTAssertNil(result.metadata)
        XCTAssertNil(result.notice)
    }

    func testLookupFailureMessagesAreUserFacing() {
        XCTAssertTrue(BarcodeLookupResult.Notice.rateLimited.message.contains("limit"))
        XCTAssertTrue(BarcodeLookupResult.Notice.unavailable.message.contains("unavailable"))
        XCTAssertTrue(BarcodeLookupResult.Notice.notFound.message.contains("No product details"))
    }
}
