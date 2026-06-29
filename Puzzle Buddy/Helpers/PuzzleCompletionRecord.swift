//
//  PuzzleCompletionRecord.swift
//  Puzzle Buddy
//

import Foundation
import SwiftData

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

    convenience init(from completion: PuzzleCompletion, puzzleID: UUID) {
        self.init(
            id: completion.id,
            puzzleID: puzzleID,
            completionNumber: completion.completionNumber,
            startedAt: completion.startedAt,
            completedAt: completion.completedAt,
            timeSpentHours: completion.timeSpentHours,
            timeSpentMinutes: completion.timeSpentMinutes,
            rating: completion.rating
        )
    }

    func toPuzzleCompletion() -> PuzzleCompletion {
        PuzzleCompletion(
            id: id,
            completionNumber: completionNumber,
            startedAt: startedAt,
            completedAt: completedAt,
            timeSpentHours: timeSpentHours,
            timeSpentMinutes: timeSpentMinutes,
            rating: rating
        )
    }
}
