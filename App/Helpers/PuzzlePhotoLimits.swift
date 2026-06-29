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
    enum MoveDirection {
        case earlier
        case later
    }

    static func photosInOrder(_ photos: [PuzzlePhoto]) -> [PuzzlePhoto] {
        photos.sorted { $0.sortOrder < $1.sortOrder }
    }

    static func coverImage(from photos: [PuzzlePhoto]) -> UIImage? {
        photosInOrder(photos).first?.image
    }

    /// Assigns 0…n `sortOrder` in the given array order (does not re-sort).
    static func normalizedSortOrders(_ photos: [PuzzlePhoto]) -> [PuzzlePhoto] {
        photos.enumerated().map { index, photo in
            var copy = photo
            copy.sortOrder = index
            return copy
        }
    }

    /// Sorts by `sortOrder` then reindexes 0…n.
    static func sortedAndNormalized(_ photos: [PuzzlePhoto]) -> [PuzzlePhoto] {
        normalizedSortOrders(photosInOrder(photos))
    }

    static func movingPhoto(id photoID: UUID, before destinationID: UUID, in photos: [PuzzlePhoto]) -> [PuzzlePhoto] {
        var ordered = photosInOrder(photos)
        guard let fromIndex = ordered.firstIndex(where: { $0.id == photoID }),
              let toIndex = ordered.firstIndex(where: { $0.id == destinationID }),
              fromIndex != toIndex else {
            return photos
        }

        let photo = ordered.remove(at: fromIndex)
        let adjustedIndex = toIndex > fromIndex ? toIndex - 1 : toIndex
        ordered.insert(photo, at: adjustedIndex)
        return normalizedSortOrders(ordered)
    }

    static func movingPhotoOneStep(id photoID: UUID, direction: MoveDirection, in photos: [PuzzlePhoto]) -> [PuzzlePhoto] {
        let ordered = photosInOrder(photos)
        guard let index = ordered.firstIndex(where: { $0.id == photoID }) else { return photos }

        switch direction {
        case .earlier:
            guard index > 0 else { return photos }
            return movingPhoto(id: photoID, before: ordered[index - 1].id, in: photos)
        case .later:
            guard index < ordered.count - 1 else { return photos }
            if index + 2 < ordered.count {
                return movingPhoto(id: photoID, before: ordered[index + 2].id, in: photos)
            }
            return movingPhotoToEnd(id: photoID, in: photos)
        }
    }

    static func movingPhotoToCover(id photoID: UUID, in photos: [PuzzlePhoto]) -> [PuzzlePhoto] {
        let ordered = photosInOrder(photos)
        guard let first = ordered.first, first.id != photoID else { return photos }
        return movingPhoto(id: photoID, before: first.id, in: photos)
    }

    static func movingPhotoToEnd(id photoID: UUID, in photos: [PuzzlePhoto]) -> [PuzzlePhoto] {
        var ordered = photosInOrder(photos)
        guard let fromIndex = ordered.firstIndex(where: { $0.id == photoID }),
              fromIndex < ordered.count - 1 else {
            return photos
        }

        let photo = ordered.remove(at: fromIndex)
        ordered.append(photo)
        return normalizedSortOrders(ordered)
    }

    /// Legacy name — use `photosInOrder(_:)`.
    static func sorted(_ photos: [PuzzlePhoto]) -> [PuzzlePhoto] {
        photosInOrder(photos)
    }
}
