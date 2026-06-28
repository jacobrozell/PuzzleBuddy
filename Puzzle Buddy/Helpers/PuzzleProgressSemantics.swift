//
//  PuzzleProgressSemantics.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleProgressSemantics {
    static func clamped(_ value: Int) -> Int {
        min(max(value, 0), 100)
    }

    static func status(for progress: Int) -> Puzzle.Status {
        switch clamped(progress) {
        case 0:
            return .todo
        case 100:
            return .completed
        default:
            return .inProgress
        }
    }

    static func progress(for status: Puzzle.Status, current: Int) -> Int {
        switch status {
        case .wishlist, .todo, .abandoned:
            return 0
        case .completed:
            return 100
        case .inProgress:
            let clamped = clamped(current)
            if clamped == 0 || clamped == 100 {
                return 10
            }
            return clamped
        }
    }

    static func displayLabel(for progress: Int) -> String {
        "\(clamped(progress))% complete"
    }
}
