//
//  PuzzleCollectionExporterTests.swift
//  Puzzle BuddyTests
//

import UIKit
import XCTest
@testable import Puzzle_Buddy

final class PuzzleCollectionExporterTests: XCTestCase {
    func testExportsJSONWithPuzzleFields() throws {
        let puzzle = Puzzle.fixture(name: "Alpine", pieces: 1000, rating: .four)
        puzzle.source = "Galison"
        puzzle.barcode = "012345678905"
        puzzle.status = .inProgress
        puzzle.progressPercent = 40

        let data = try PuzzleCollectionExporter.jsonData(from: [puzzle])
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let puzzles = try XCTUnwrap(json?["puzzles"] as? [[String: Any]])
        XCTAssertEqual(puzzles.first?["name"] as? String, "Alpine")
        XCTAssertEqual(puzzles.first?["source"] as? String, "Galison")
        XCTAssertEqual(puzzles.first?["barcode"] as? String, "012345678905")
        XCTAssertEqual(puzzles.first?["progressPercent"] as? Int, 40)
    }

    func testExportsCSVEscapesCommas() throws {
        let puzzle = Puzzle.fixture(name: "Cozy, Cabin", pieces: 500)
        puzzle.notes = "Line one"

        let data = try PuzzleCollectionExporter.csvData(from: [puzzle])
        let csv = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(csv.contains("\"Cozy, Cabin\""))
        XCTAssertTrue(csv.hasPrefix("Title,Brand,Piece Count,Barcode,Folder"))
    }

    func testExportsIPDbCompatibleColumns() throws {
        let puzzle = Puzzle.fixture(name: "Winter Village", pieces: 1000, rating: .fourHalf)
        puzzle.source = "Ravensburger"
        puzzle.barcode = "4005556197523"
        puzzle.status = .completed
        puzzle.progressPercent = 100
        puzzle.difficulty = .three
        puzzle.notes = "Thrift find\nManufacturer ID: 4354-12"
        puzzle.completionDate = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: "2024-11-02") ?? Date()
        }()

        let data = try PuzzleCollectionExporter.csvData(from: [puzzle])
        let csv = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(csv.contains("Wishlist").self == false)
        XCTAssertTrue(csv.contains("Completed"))
        XCTAssertTrue(csv.contains("4354-12"))
        XCTAssertTrue(csv.contains("2024-11-02"))
        XCTAssertTrue(csv.contains("Thrift find"))
    }

    func testExportedCSVRoundTripsThroughImporter() throws {
        let puzzle = Puzzle.fixture(name: "Mountain Cabin", pieces: 750, rating: .three)
        puzzle.source = "Buffalo Games"
        puzzle.barcode = "818870028198"
        puzzle.status = .inProgress
        puzzle.progressPercent = 35
        puzzle.difficulty = .two
        puzzle.notes = "Started last weekend"

        let data = try PuzzleCollectionExporter.csvData(from: [puzzle])
        let imported = try IPDbCSVImporter.puzzles(from: data)
        XCTAssertEqual(imported.count, 1)

        let roundTripped = try XCTUnwrap(imported.first)
        XCTAssertEqual(roundTripped.name, "Mountain Cabin")
        XCTAssertEqual(roundTripped.source, "Buffalo Games")
        XCTAssertEqual(roundTripped.pieces, 750)
        XCTAssertEqual(roundTripped.barcode, "818870028198")
        XCTAssertEqual(roundTripped.status, .inProgress)
        XCTAssertEqual(roundTripped.progressPercent, 35)
        XCTAssertEqual(roundTripped.rating, .three)
        XCTAssertEqual(roundTripped.difficulty, .two)
        XCTAssertEqual(roundTripped.notes, "Started last weekend")
    }

    func testExportsToDoFolderForOwnedBacklog() throws {
        let puzzle = Puzzle.fixture(name: "Harbor Sunset", pieces: 500)
        puzzle.source = "Galison"
        puzzle.status = .todo

        let data = try PuzzleCollectionExporter.csvData(from: [puzzle])
        let csv = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(csv.contains("To-Do"))
    }

    func testExportsWishlistFolderForWishlistStatus() throws {
        let puzzle = Puzzle.fixture(name: "Future Buy", pieces: 500)
        puzzle.status = .wishlist

        let data = try PuzzleCollectionExporter.csvData(from: [puzzle])
        let csv = String(decoding: data, as: UTF8.self)
        XCTAssertTrue(csv.contains("Wishlist"))
    }

    func testExportsExpandedMetadataInJSON() throws {
        var puzzle = Puzzle.fixture(name: "Expanded", pieces: 1000)
        puzzle.puzzleShape = .round
        puzzle.cutType = .grid
        puzzle.dimensionsText = "68 × 49 cm"
        puzzle.purchasePrice = 19.99
        puzzle.purchaseCurrencyCode = "USD"
        puzzle.timesCompleted = 2
        puzzle.photos = [PuzzlePhoto(sortOrder: 0, image: testImage())]
        puzzle.completions = [
            PuzzleCompletion(completionNumber: 1, completedAt: Date()),
            PuzzleCompletion(completionNumber: 2, completedAt: Date())
        ]

        let data = try PuzzleCollectionExporter.jsonData(from: [puzzle])
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let puzzles = try XCTUnwrap(json?["puzzles"] as? [[String: Any]])
        let record = try XCTUnwrap(puzzles.first)

        XCTAssertEqual(json?["backupFormatVersion"] as? Int, PuzzleCollectionBackupFormat.currentVersion)
        XCTAssertEqual(record["puzzleShape"] as? String, PuzzleShape.round.rawValue)
        XCTAssertEqual(record["cutType"] as? String, PuzzleCutType.grid.rawValue)
        XCTAssertEqual(record["dimensionsText"] as? String, "68 × 49 cm")
        XCTAssertEqual(record["purchasePrice"] as? Double, 19.99)
        XCTAssertEqual(record["timesCompleted"] as? Int, 2)
        XCTAssertEqual(record["photoCount"] as? Int, 1)
        let photos = try XCTUnwrap(record["photos"] as? [[String: Any]])
        XCTAssertEqual(photos.count, 1)
        let completions = try XCTUnwrap(record["completions"] as? [[String: Any]])
        XCTAssertEqual(completions.count, 2)
    }

    func testWriteTemporaryFileUsesRequestedExtension() throws {
        let puzzle = Puzzle.fixture(name: "Export Me", pieces: 300)
        let url = try PuzzleCollectionExporter.writeTemporaryFile(from: [puzzle], format: .json)
        XCTAssertEqual(url.pathExtension, "json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    private func testImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { ctx in
            UIColor.systemTeal.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }
}
