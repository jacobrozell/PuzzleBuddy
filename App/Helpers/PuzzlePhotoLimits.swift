//
//  PuzzlePhotoLimits.swift
//  Puzzle Buddy
//

import Foundation
import UIKit

enum PuzzlePhotoLimits {
    static let maxCount = 5
}

struct PuzzlePhoto: Identifiable, Equatable {
    var id: UUID
    var sortOrder: Int
    var image: UIImage?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        sortOrder: Int,
        image: UIImage? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sortOrder = sortOrder
        self.image = image
        self.createdAt = createdAt
    }

    static func == (lhs: PuzzlePhoto, rhs: PuzzlePhoto) -> Bool {
        lhs.id == rhs.id && lhs.sortOrder == rhs.sortOrder
    }
}

enum PuzzlePhotoSemantics {
    static func sorted(_ photos: [PuzzlePhoto]) -> [PuzzlePhoto] {
        photos.sorted { $0.sortOrder < $1.sortOrder }
    }

    static func coverImage(from photos: [PuzzlePhoto]) -> UIImage? {
        sorted(photos).first?.image
    }

    static func normalizedSortOrders(_ photos: [PuzzlePhoto]) -> [PuzzlePhoto] {
        sorted(photos).enumerated().map { index, photo in
            var copy = photo
            copy.sortOrder = index
            return copy
        }
    }
}
