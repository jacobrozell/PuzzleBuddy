//
//  PuzzleRecord.swift
//  Puzzle Buddy
//
//  SwiftData persistence for local puzzle storage.
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
    var status: String
    var hasMissingPieces: Bool = false
    var notes: String?
    var source: String?
    var progressPercent: Int = 0
    var isDemo: Bool = false
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
        status: String = Puzzle.Status.todo.rawValue,
        hasMissingPieces: Bool = false,
        notes: String? = nil,
        source: String? = nil,
        progressPercent: Int = 0,
        isDemo: Bool = false,
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
        self.status = status
        self.hasMissingPieces = hasMissingPieces
        self.notes = notes
        self.source = source
        self.progressPercent = progressPercent
        self.isDemo = isDemo
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
            status: puzzle.status.rawValue,
            hasMissingPieces: puzzle.hasMissingPieces,
            notes: puzzle.notes,
            source: puzzle.source,
            progressPercent: puzzle.progressPercent,
            isDemo: puzzle.isDemo,
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
        status = puzzle.status.rawValue
        hasMissingPieces = puzzle.hasMissingPieces
        notes = puzzle.notes
        source = puzzle.source
        progressPercent = puzzle.progressPercent
        isDemo = puzzle.isDemo
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
            hasMissingPieces: hasMissingPieces,
            notes: notes,
            source: source,
            progressPercent: progressPercent,
            isDemo: isDemo
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
