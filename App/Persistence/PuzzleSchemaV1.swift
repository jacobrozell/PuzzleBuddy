//
//  PuzzleSchemaV1.swift
//  Puzzle Buddy
//
//  Frozen nested models matching App Store 1.0.0 / 1.1.0 pre–On-loan store shape.
//  Do not edit these nested types — add PuzzleSchemaV2 (+ stage) instead.
//

import Foundation
import SwiftData

/// Version 1 schema — baseline for SwiftData migrations.
///
/// Nested `@Model` copies freeze the 1.0.0 fingerprint. Live app code uses
/// top-level `PuzzleRecord` / `FriendRecord` via `PuzzleSchemaV2`.
///
/// Policy for agents: `docs/swiftdata-migrations.md`
enum PuzzleSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            PuzzleRecord.self,
            PuzzlePhotoRecord.self,
            PuzzleCompletionRecord.self,
        ]
    }

    @Model
    final class PuzzleRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        var pieces: Int?
        var rating: Double
        var difficulty: String
        var estimatedTimeHours: Int?
        var estimatedTimeMinutes: Int?
        var completionDate: Date
        var startDate: Date?
        var status: String
        var hasMissingPieces: Bool = false
        var notes: String?
        var source: String?
        var purchaseLocation: String?
        var releaseYear: Int?
        var puzzleType: String = "None"
        var material: String = "None"
        var disposition: String = "None"
        var progressPercent: Int = 0
        var purchasePrice: Double?
        var purchaseCurrencyCode: String?
        var puzzleShape: String = "None"
        var cutType: String = "None"
        var dimensionsText: String?
        var timesCompleted: Int = 0
        var isDemo: Bool = false
        var barcode: String?
        var tags: [String] = []
        @Attribute(.externalStorage) var imageData: Data?

        init(
            id: UUID = UUID(),
            name: String = "",
            pieces: Int? = nil,
            rating: Double = 0,
            difficulty: String = "0",
            estimatedTimeHours: Int? = nil,
            estimatedTimeMinutes: Int? = nil,
            completionDate: Date = Date(),
            startDate: Date? = nil,
            status: String = "To-Do",
            hasMissingPieces: Bool = false,
            notes: String? = nil,
            source: String? = nil,
            purchaseLocation: String? = nil,
            releaseYear: Int? = nil,
            puzzleType: String = "None",
            material: String = "None",
            disposition: String = "None",
            progressPercent: Int = 0,
            purchasePrice: Double? = nil,
            purchaseCurrencyCode: String? = nil,
            puzzleShape: String = "None",
            cutType: String = "None",
            dimensionsText: String? = nil,
            timesCompleted: Int = 0,
            isDemo: Bool = false,
            barcode: String? = nil,
            tags: [String] = [],
            imageData: Data? = nil
        ) {
            self.id = id
            self.name = name
            self.pieces = pieces
            self.rating = rating
            self.difficulty = difficulty
            self.estimatedTimeHours = estimatedTimeHours
            self.estimatedTimeMinutes = estimatedTimeMinutes
            self.completionDate = completionDate
            self.startDate = startDate
            self.status = status
            self.hasMissingPieces = hasMissingPieces
            self.notes = notes
            self.source = source
            self.purchaseLocation = purchaseLocation
            self.releaseYear = releaseYear
            self.puzzleType = puzzleType
            self.material = material
            self.disposition = disposition
            self.progressPercent = progressPercent
            self.purchasePrice = purchasePrice
            self.purchaseCurrencyCode = purchaseCurrencyCode
            self.puzzleShape = puzzleShape
            self.cutType = cutType
            self.dimensionsText = dimensionsText
            self.timesCompleted = timesCompleted
            self.isDemo = isDemo
            self.barcode = barcode
            self.tags = tags
            self.imageData = imageData
        }
    }

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
    }

    @Model
    final class PuzzleCompletionRecord {
        @Attribute(.unique) var id: UUID
        var puzzleID: UUID
        var completionNumber: Int
        var startedAt: Date?
        var completedAt: Date
        var timeSpentHours: Int?
        var timeSpentMinutes: Int?
        var rating: Double?

        init(
            id: UUID = UUID(),
            puzzleID: UUID,
            completionNumber: Int,
            startedAt: Date? = nil,
            completedAt: Date,
            timeSpentHours: Int? = nil,
            timeSpentMinutes: Int? = nil,
            rating: Double? = nil
        ) {
            self.id = id
            self.puzzleID = puzzleID
            self.completionNumber = completionNumber
            self.startedAt = startedAt
            self.completedAt = completedAt
            self.timeSpentHours = timeSpentHours
            self.timeSpentMinutes = timeSpentMinutes
            self.rating = rating
        }
    }
}
