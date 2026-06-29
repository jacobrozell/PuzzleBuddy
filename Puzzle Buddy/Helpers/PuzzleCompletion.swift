//
//  PuzzleCompletion.swift
//  Puzzle Buddy
//

import Foundation

struct PuzzleCompletion: Identifiable, Equatable {
    var id: UUID
    var completionNumber: Int
    var startedAt: Date?
    var completedAt: Date
    var timeSpentHours: Int?
    var timeSpentMinutes: Int?
    var rating: Double?

    init(
        id: UUID = UUID(),
        completionNumber: Int,
        startedAt: Date? = nil,
        completedAt: Date,
        timeSpentHours: Int? = nil,
        timeSpentMinutes: Int? = nil,
        rating: Double? = nil
    ) {
        self.id = id
        self.completionNumber = completionNumber
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.timeSpentHours = timeSpentHours
        self.timeSpentMinutes = timeSpentMinutes
        self.rating = rating
    }

    var timeSpentLabel: String? {
        let hourValue = max(timeSpentHours ?? 0, 0)
        let minuteValue = max(timeSpentMinutes ?? 0, 0)
        guard hourValue > 0 || minuteValue > 0 else { return nil }

        var parts: [String] = []
        if hourValue > 0 {
            parts.append(hourValue == 1 ? "1 hr" : "\(hourValue) hr")
        }
        if minuteValue > 0 {
            parts.append(minuteValue == 1 ? "1 min" : "\(minuteValue) min")
        }
        return parts.joined(separator: " ")
    }
}
