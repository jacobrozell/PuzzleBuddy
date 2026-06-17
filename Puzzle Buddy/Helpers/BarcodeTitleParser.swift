//
//  BarcodeTitleParser.swift
//  Puzzle Buddy
//

import Foundation

enum BarcodeTitleParser {
    private static let pieceCountPattern = #/(?i)(\d{2,5})\s*(?:piece|pieces|pc|pce|pcs)\b/#

    static func pieces(from title: String?) -> Int? {
        guard let title, !title.isEmpty else { return nil }
        guard let match = title.firstMatch(of: pieceCountPattern) else { return nil }
        return Int(match.1)
    }

    static func cleanedTitle(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
