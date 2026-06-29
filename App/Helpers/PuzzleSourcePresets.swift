//
//  PuzzleSourcePresets.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzlePieceCount {
    static let commonValues = [100, 300, 500, 750, 1000, 1500, 2000]

    static func formatted(_ count: Int) -> String {
        count.formatted()
    }

    static func matchesCommon(_ pieces: Int?) -> Bool {
        guard let pieces else { return false }
        return commonValues.contains(pieces)
    }
}
