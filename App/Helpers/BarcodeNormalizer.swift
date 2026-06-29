//
//  BarcodeNormalizer.swift
//  Puzzle Buddy
//

import Foundation

enum BarcodeNormalizer {
    static let maxLength = 32
    private static let validLengths = 6...14

    static func normalize(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let digits = raw.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        guard validLengths.contains(digits.count) else { return nil }
        return String(digits.prefix(maxLength))
    }

    /// Extracts digits without length validation (e.g. before showing an invalid-barcode message).
    static func optionalDigits(from raw: String) -> String? {
        let digits = raw.filter(\.isNumber)
        return digits.isEmpty ? nil : digits
    }
}
