//
//  PuzzleSourcePresets.swift
//  Puzzle Buddy
//

import Foundation

enum PuzzleSourcePreset: String, CaseIterable, Identifiable {
    case gift
    case amazon
    case thrift
    case garageSale
    case retail

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gift: "Gift"
        case .amazon: "Amazon"
        case .thrift: "Thrift store"
        case .garageSale: "Garage sale"
        case .retail: "Retail store"
        }
    }

    var suggestedText: String { label }
}

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
