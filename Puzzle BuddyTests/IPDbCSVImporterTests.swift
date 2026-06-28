//
//  IPDbCSVImporterTests.swift
//  Puzzle BuddyTests
//

import XCTest
@testable import Puzzle_Buddy

final class IPDbCSVImporterTests: XCTestCase {
    func testParsesStandardIPDbStyleCSV() throws {
        let csv = """
        Title,Brand,Piece Count,Barcode,Status,Notes
        Winter Lights,Galison,1000,012345678905,Completed,Gift from Mom
        Harbor View,Ravensburger,500,,Wishlist,
        """

        let puzzles = try IPDbCSVImporter.puzzles(from: Data(csv.utf8))
        XCTAssertEqual(puzzles.count, 2)

        XCTAssertEqual(puzzles[0].name, "Winter Lights")
        XCTAssertEqual(puzzles[0].source, "Galison")
        XCTAssertEqual(puzzles[0].pieces, 1000)
        XCTAssertEqual(puzzles[0].barcode, "012345678905")
        XCTAssertEqual(puzzles[0].status, .completed)
        XCTAssertEqual(puzzles[0].notes, "Gift from Mom")

        XCTAssertEqual(puzzles[1].name, "Harbor View")
        XCTAssertEqual(puzzles[1].status, .wishlist)
        XCTAssertNil(puzzles[1].barcode)
    }

    func testParsesSemicolonDelimitedCSV() throws {
        let csv = """
        Title;Brand;Piece Count;Barcode
        Cabin Retreat;Buffalo Games;750;818870028198
        """

        let puzzles = try IPDbCSVImporter.puzzles(from: Data(csv.utf8))
        XCTAssertEqual(puzzles.count, 1)
        XCTAssertEqual(puzzles.first?.barcode, "818870028198")
    }

    func testIncludesManufacturerIDInNotes() throws {
        let record: [String: String] = [
            "Title": "Death Foretold",
            "Brand": "Parker Brothers",
            "Piece Count": "500",
            "Manufacturer ID": "4354-9"
        ]

        let puzzle = try XCTUnwrap(IPDbCSVImporter.puzzle(from: record))
        XCTAssertTrue(puzzle.notes?.contains("4354-9") == true)
    }

    func testThrowsWhenNoValidRows() {
        let csv = "Brand,Piece Count\nGalison,1000\n"
        XCTAssertThrowsError(try IPDbCSVImporter.puzzles(from: Data(csv.utf8))) { error in
            XCTAssertTrue(error is IPDbCSVImportError)
        }
    }

    func testParsesSampleIPDbExportFixture() throws {
        let data = try loadFixture(named: "ipdb-sample-export", extension: "csv")
        let puzzles = try IPDbCSVImporter.puzzles(from: data)
        XCTAssertEqual(puzzles.count, 4)

        let inProgress = try XCTUnwrap(puzzles.first { $0.name == "Mountain Cabin" })
        XCTAssertEqual(inProgress.status, .inProgress)
        XCTAssertEqual(inProgress.progressPercent, 35)
        XCTAssertEqual(inProgress.barcode, "818870028198")

        let wishlist = try XCTUnwrap(puzzles.first { $0.name == "Harbor Sunset" })
        XCTAssertEqual(wishlist.status, .wishlist)

        let completed = try XCTUnwrap(puzzles.first { $0.name == "Mystery Lake" })
        XCTAssertEqual(completed.status, .completed)
        XCTAssertEqual(completed.progressPercent, 100)
    }

    func testParsesProgressPercentColumn() throws {
        let csv = """
        Title,Brand,Piece Count,Folder,Progress Percent
        Tabletop Sky,Galison,500,In-Progress,45
        """
        let puzzle = try XCTUnwrap(IPDbCSVImporter.puzzles(from: Data(csv.utf8)).first)
        XCTAssertEqual(puzzle.progressPercent, 45)
        XCTAssertEqual(puzzle.status, .inProgress)
    }

    private func loadFixture(named name: String, extension ext: String) throws -> Data {
        let bundle = Bundle(for: IPDbCSVImporterTests.self)
        guard let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Fixtures")
            ?? bundle.url(forResource: name, withExtension: ext) else {
            XCTFail("Missing fixture \(name).\(ext)")
            throw IPDbCSVImportError.emptyFile
        }
        return try Data(contentsOf: url)
    }
}
