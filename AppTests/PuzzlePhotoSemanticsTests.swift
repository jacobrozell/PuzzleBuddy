//
//  PuzzlePhotoSemanticsTests.swift
//  Puzzle BuddyTests
//

import UIKit
import XCTest
@testable import PuzzleBuddy

final class PuzzlePhotoSemanticsTests: XCTestCase {
    func testNormalizedSortOrdersAreZeroBased() {
        let photos = [
            PuzzlePhoto(sortOrder: 2, image: testImage()),
            PuzzlePhoto(sortOrder: 0, image: testImage())
        ]
        let normalized = PuzzlePhotoSemantics.sortedAndNormalized(photos)
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

    func testMovingPhotoBeforeDestinationUpdatesCover() {
        let first = PuzzlePhoto(sortOrder: 0, image: testImage(color: .red))
        let second = PuzzlePhoto(sortOrder: 1, image: testImage(color: .blue))
        let third = PuzzlePhoto(sortOrder: 2, image: testImage(color: .green))
        let photos = [first, second, third]

        let reordered = PuzzlePhotoSemantics.movingPhoto(id: third.id, before: first.id, in: photos)
        XCTAssertEqual(reordered.map(\.id), [third.id, first.id, second.id])
        XCTAssertEqual(PuzzlePhotoSemantics.coverImage(from: reordered), third.image)
    }

    func testMovingPhotoOneStepLater() {
        let first = PuzzlePhoto(sortOrder: 0, image: testImage(color: .red))
        let second = PuzzlePhoto(sortOrder: 1, image: testImage(color: .blue))
        let third = PuzzlePhoto(sortOrder: 2, image: testImage(color: .green))
        let photos = [first, second, third]

        let reordered = PuzzlePhotoSemantics.movingPhotoOneStep(id: first.id, direction: .later, in: photos)
        XCTAssertEqual(reordered.map(\.id), [second.id, first.id, third.id])
    }

    func testMovingPhotoToEnd() {
        let first = PuzzlePhoto(sortOrder: 0, image: testImage(color: .red))
        let second = PuzzlePhoto(sortOrder: 1, image: testImage(color: .blue))
        let third = PuzzlePhoto(sortOrder: 2, image: testImage(color: .green))
        let photos = [first, second, third]

        let reordered = PuzzlePhotoSemantics.movingPhotoToEnd(id: first.id, in: photos)
        XCTAssertEqual(reordered.map(\.id), [second.id, third.id, first.id])
    }

    func testMovingPhotoToCover() {
        let first = PuzzlePhoto(sortOrder: 0, image: testImage(color: .red))
        let second = PuzzlePhoto(sortOrder: 1, image: testImage(color: .blue))
        let photos = [first, second]

        let reordered = PuzzlePhotoSemantics.movingPhotoToCover(id: second.id, in: photos)
        XCTAssertEqual(reordered.map(\.id), [second.id, first.id])
        XCTAssertEqual(PuzzlePhotoSemantics.coverImage(from: reordered), second.image)
    }

    private func testImage(color: UIColor = .gray) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { ctx in
            color.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
    }
}