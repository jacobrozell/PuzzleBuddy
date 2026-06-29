//
//  PurchasePriceFormatting.swift
//  Puzzle Buddy
//

import Foundation

enum PurchasePriceFormatting {
    static func displayLabel(price: Double, currencyCode: String?) -> String {
        let code = currencyCode ?? Locale.current.currency?.identifier ?? "USD"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? String(format: "%.2f", price)
    }

    static func parse(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let sanitized = trimmed
            .replacingOccurrences(of: "[^0-9.,]", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Double(sanitized), value >= 0 else { return nil }
        return min(value, 999_999.99)
    }
}
