//
//  CSVTableTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import PuzzleBuddy

final class CSVTableTests: XCTestCase {
    func testParseQuotedFieldWithEmbeddedComma() {
        let rows = CSVTable.parse("""
        "Title, with comma",Brand
        Winter Lights,Galison
        """)
        XCTAssertEqual(rows.count, 2)
        XCTAssertEqual(rows[0][0], "Title, with comma")
        XCTAssertEqual(rows[0][1], "Brand")
    }

    func testParseEmbeddedNewlinesInQuotedField() {
        let rows = CSVTable.parse("""
        Title,Notes
        "Harbor","Line one
        Line two"
        """)
        XCTAssertEqual(rows.count, 2)
        XCTAssertTrue(rows[1][1].contains("Line one"))
        XCTAssertTrue(rows[1][1].contains("Line two"))
    }

    func testParseSemicolonDelimiter() {
        let rows = CSVTable.parse("Title;Brand\nWinter;Galison\n")
        XCTAssertEqual(rows.first?.count, 2)
        XCTAssertEqual(rows[1][0], "Winter")
    }

    func testParseDelimitedRowsStripsUTF8BOM() {
        let csv = "\u{FEFF}Title,Brand\nWinter,Galison\n"
        let parsed = CSVTable.parseDelimitedRows(csv)
        XCTAssertEqual(parsed.headers, ["Title", "Brand"])
        XCTAssertEqual(parsed.records.first?["Title"], "Winter")
    }

    func testParseDelimitedRowsHandlesRaggedRows() {
        let parsed = CSVTable.parseDelimitedRows("""
        Title,Brand,Pieces
        Winter,Galison
        Harbor,Ravensburger,500,Extra
        """)
        XCTAssertEqual(parsed.records.count, 2)
        XCTAssertEqual(parsed.records[0]["Pieces"], "")
        XCTAssertEqual(parsed.records[1]["Pieces"], "500")
    }

    func testDelimiterPrefersCommaWhenBothPresent() {
        let rows = [["Title,Brand;Extra"]]
        XCTAssertEqual(CSVTable.delimiter(for: rows), ",")
    }
}
