//
//  PuzzlePhotoRecord.swift
//  Puzzle Buddy
//

import Foundation
import SwiftData
import UIKit

@Model
final class PuzzlePhotoRecord {
    @Attribute(.unique) var id: UUID
    var puzzleID: UUID
    var sortOrder: Int
    @Attribute(.externalStorage) var imageData: Data?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        puzzleID: UUID,
        sortOrder: Int,
        imageData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.puzzleID = puzzleID
        self.sortOrder = sortOrder
        self.imageData = imageData
        self.createdAt = createdAt
    }

    convenience init(from photo: PuzzlePhoto, puzzleID: UUID) {
        self.init(
            id: photo.id,
            puzzleID: puzzleID,
            sortOrder: photo.sortOrder,
            imageData: photo.image?.jpegData(compressionQuality: 0.30),
            createdAt: photo.createdAt
        )
    }

    func toPuzzlePhoto() -> PuzzlePhoto {
        var image: UIImage?
        if let imageData, let loaded = UIImage(data: imageData) {
            image = loaded
        }
        return PuzzlePhoto(
            id: id,
            sortOrder: sortOrder,
            image: image,
            createdAt: createdAt
        )
    }
}
