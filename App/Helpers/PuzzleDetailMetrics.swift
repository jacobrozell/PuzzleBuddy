//
//  PuzzleDetailMetrics.swift
//  Puzzle Buddy
//

import Foundation

// MARK: - PuzzleDetailMetrics

/// Per-puzzle derived metrics for the detail stats panel (no schema change).
struct PuzzleDetailMetrics: Equatable {
    let timeBucketLabel: String?
    let hoursPer1000Pieces: Double?

    static func compute(pieces: Int?, time: Puzzle.PuzzleTime?) -> PuzzleDetailMetrics {
        let minutes = totalMinutes(from: time)
        let bucket = minutes.map(timeBucketLabel(forMinutes:))

        let hoursPer1000: Double? = {
            guard let minutes, let pieces, pieces > 0 else { return nil }
            let hours = Double(minutes) / 60.0
            return hours / (Double(pieces) / 1000.0)
        }()

        return PuzzleDetailMetrics(
            timeBucketLabel: bucket,
            hoursPer1000Pieces: hoursPer1000
        )
    }

    var formattedHoursPer1000Pieces: String? {
        guard let hoursPer1000Pieces else { return nil }
        if hoursPer1000Pieces >= 10 {
            return "\(Int(hoursPer1000Pieces.rounded())) hrs per 1,000 pieces"
        }
        if hoursPer1000Pieces >= 1 {
            let rounded = (hoursPer1000Pieces * 10).rounded() / 10
            if rounded == rounded.rounded() {
                return "\(Int(rounded)) hrs per 1,000 pieces"
            }
            return String(format: "%.1f hrs per 1,000 pieces", rounded)
        }
        let minutesPer1000 = hoursPer1000Pieces * 60
        if minutesPer1000 >= 10 {
            return "\(Int(minutesPer1000.rounded())) min per 1,000 pieces"
        }
        return String(format: "%.1f min per 1,000 pieces", minutesPer1000)
    }

    // MARK: - Rules

    static func timeBucketLabel(forMinutes minutes: Int) -> String {
        switch minutes {
        case ..<240:
            return "Quick finish"
        case 240..<720:
            return "Weekend puzzle"
        default:
            return "Marathon project"
        }
    }

    static func totalMinutes(from time: Puzzle.PuzzleTime?) -> Int? {
        guard let time,
              let hours = time.hours,
              let minutes = time.minutes else {
            return nil
        }
        return max((hours * 60) + minutes, 0)
    }
}
