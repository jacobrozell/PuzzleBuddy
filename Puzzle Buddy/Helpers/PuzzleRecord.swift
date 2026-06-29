//
//  PuzzleRecord.swift
//  Puzzle Buddy
//

import Foundation
import SwiftData
import UIKit

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
    var puzzleType: String = PuzzleType.none.rawValue
    var material: String = PuzzleMaterial.none.rawValue
    var disposition: String = PuzzleDisposition.none.rawValue
    var progressPercent: Int = 0
    var purchasePrice: Double?
    var purchaseCurrencyCode: String?
    var puzzleShape: String = PuzzleShape.none.rawValue
    var cutType: String = PuzzleCutType.none.rawValue
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
        difficulty: String = Puzzle.Difficulty.none.rawValue,
        estimatedTimeHours: Int? = nil,
        estimatedTimeMinutes: Int? = nil,
        completionDate: Date = Date(),
        startDate: Date? = nil,
        status: String = Puzzle.Status.todo.rawValue,
        hasMissingPieces: Bool = false,
        notes: String? = nil,
        source: String? = nil,
        purchaseLocation: String? = nil,
        releaseYear: Int? = nil,
        puzzleType: String = PuzzleType.none.rawValue,
        material: String = PuzzleMaterial.none.rawValue,
        disposition: String = PuzzleDisposition.none.rawValue,
        progressPercent: Int = 0,
        purchasePrice: Double? = nil,
        purchaseCurrencyCode: String? = nil,
        puzzleShape: String = PuzzleShape.none.rawValue,
        cutType: String = PuzzleCutType.none.rawValue,
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
        self.tags = PuzzleTagSemantics.sanitizedTags(tags)
        self.imageData = imageData
    }

    convenience init(from puzzle: Puzzle) {
        let time = puzzle.estimatedTimeSpent
        self.init(
            id: puzzle.id,
            name: puzzle.name,
            pieces: puzzle.pieces,
            rating: puzzle.rating.rawValue,
            difficulty: puzzle.difficulty.rawValue,
            estimatedTimeHours: time?.hours,
            estimatedTimeMinutes: time?.minutes,
            completionDate: puzzle.completionDate,
            startDate: puzzle.startDate,
            status: puzzle.status.rawValue,
            hasMissingPieces: puzzle.hasMissingPieces,
            notes: puzzle.notes,
            source: puzzle.source,
            purchaseLocation: puzzle.purchaseLocation,
            releaseYear: puzzle.releaseYear,
            puzzleType: puzzle.puzzleType.rawValue,
            material: puzzle.material.rawValue,
            disposition: puzzle.disposition.rawValue,
            progressPercent: puzzle.progressPercent,
            purchasePrice: puzzle.purchasePrice,
            purchaseCurrencyCode: puzzle.purchaseCurrencyCode,
            puzzleShape: puzzle.puzzleShape.rawValue,
            cutType: puzzle.cutType.rawValue,
            dimensionsText: puzzle.dimensionsText,
            timesCompleted: puzzle.timesCompleted,
            isDemo: puzzle.isDemo,
            barcode: puzzle.barcode,
            tags: puzzle.tags,
            imageData: puzzle.image?.jpegData(compressionQuality: 0.30)
        )
    }

    func apply(from puzzle: Puzzle) {
        name = puzzle.name
        pieces = puzzle.pieces
        rating = puzzle.rating.rawValue
        difficulty = puzzle.difficulty.rawValue
        estimatedTimeHours = puzzle.estimatedTimeSpent?.hours
        estimatedTimeMinutes = puzzle.estimatedTimeSpent?.minutes
        completionDate = puzzle.completionDate
        startDate = puzzle.startDate
        status = puzzle.status.rawValue
        hasMissingPieces = puzzle.hasMissingPieces
        notes = puzzle.notes
        source = puzzle.source
        purchaseLocation = puzzle.purchaseLocation
        releaseYear = puzzle.releaseYear
        puzzleType = puzzle.puzzleType.rawValue
        material = puzzle.material.rawValue
        disposition = puzzle.disposition.rawValue
        progressPercent = puzzle.progressPercent
        purchasePrice = puzzle.purchasePrice
        purchaseCurrencyCode = puzzle.purchaseCurrencyCode
        puzzleShape = puzzle.puzzleShape.rawValue
        cutType = puzzle.cutType.rawValue
        dimensionsText = puzzle.dimensionsText
        timesCompleted = puzzle.timesCompleted
        isDemo = puzzle.isDemo
        barcode = BarcodeNormalizer.normalize(puzzle.barcode)
        tags = PuzzleTagSemantics.sanitizedTags(puzzle.tags)
        imageData = puzzle.image?.jpegData(compressionQuality: 0.30)
    }

    func toPuzzle() -> Puzzle {
        let puzzle = Puzzle(
            name: name,
            pieces: pieces,
            rating: Puzzle.Rating(rawValue: rating) ?? .none,
            difficulty: Puzzle.Difficulty(rawValue: difficulty) ?? .none,
            estimatedTimeSpent: estimatedTimePuzzleTime,
            completionDate: completionDate,
            status: Puzzle.Status(rawValue: status) ?? .todo,
            startDate: startDate,
            hasMissingPieces: hasMissingPieces,
            notes: notes,
            source: source,
            purchaseLocation: purchaseLocation,
            releaseYear: releaseYear,
            puzzleType: PuzzleType(rawValue: puzzleType) ?? .none,
            material: PuzzleMaterial(rawValue: material) ?? .none,
            disposition: PuzzleDisposition(rawValue: disposition) ?? .none,
            progressPercent: progressPercent,
            purchasePrice: purchasePrice,
            purchaseCurrencyCode: purchaseCurrencyCode,
            puzzleShape: PuzzleShape(rawValue: puzzleShape) ?? .none,
            cutType: PuzzleCutType(rawValue: cutType) ?? .none,
            dimensionsText: dimensionsText,
            timesCompleted: timesCompleted,
            isDemo: isDemo,
            barcode: barcode,
            tags: tags
        )
        puzzle.id = id
        if let imageData, let image = UIImage(data: imageData) {
            puzzle.image = image
        }
        return puzzle
    }

    private var estimatedTimePuzzleTime: Puzzle.PuzzleTime? {
        guard estimatedTimeHours != nil || estimatedTimeMinutes != nil else { return nil }
        return Puzzle.PuzzleTime(hours: estimatedTimeHours, minutes: estimatedTimeMinutes)
    }
}
