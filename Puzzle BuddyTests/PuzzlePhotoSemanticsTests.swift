//
//  PuzzlePhotoSemanticsTests.swift
//  Puzzle BuddyTests
//

import UIKit
import XCTest
@testable import Puzzle_Buddy

final class PuzzlePhotoSemanticsTests: XCTestCase {
    func testNormalizedSortOrdersAreZeroBased() {
        let photos = [
            PuzzlePhoto(sortOrder: 2, image: testImage()),
            PuzzlePhoto(sortOrder: 0, image: testImage())
        ]
        let normalized = PuzzlePhotoSemantics.normalizedSortOrders(photos)
        XCTAssertEqual(normalized.map(\.sortOrder), [0, 1])
    }

    func testCoverImageUsesLowestSortOrder() {
        let photos = [
            PuzzlePhoto(sortOrder: 1, image: testImage()),
            PuzzlePhoto(sortOrder: 0, image: testImage())
        ]
        XCTAssertEqual(PuzzlePhotoSemantics.sorted(photos).first?.sortOrder, 0)
        XCTAssertNotNil(PuzzlePhotoSemantics.coverImage(from: photos))
    }

    func testPrepareForPersistenceEnforcesPhotoLimit() {
        var puzzle = Puzzle.fixture(name: "Many", pieces: 100)
        puzzle.photos = (0..<7).map { PuzzlePhoto(sortOrder: $0, image: testImage()) }
        puzzle.prepareForPersistence()
        XCTAssertEqual(puzzle.photos.count, PuzzlePhotoLimits.maxCount)
        XCTAssertEqual(puzzle.photos.map(\.sortOrder), Array(0..<PuzzlePhotoLimits.maxCount))
    }

    private func testImage(color: UIColor = .gray) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { ctx in
            color.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }
}