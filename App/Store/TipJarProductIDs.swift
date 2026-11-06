//
//  TipJarProductIDs.swift
//  Puzzle Buddy
//

import Foundation

enum TipJarProductIDs {
    static let small = "com.jacobrozell.Puzzle-Buddy.tip.small"
    static let medium = "com.jacobrozell.Puzzle-Buddy.tip.medium"
    static let large = "com.jacobrozell.Puzzle-Buddy.tip.large"
    static let all = [small, medium, large]

    static func rank(_ productID: String) -> Int {
        all.firstIndex(of: productID) ?? Int.max
    }

    static func sorted(_ productIDs: [String]) -> [String] {
        productIDs.sorted { rank($0) < rank($1) }
    }

    static func accessibilitySuffix(for productID: String) -> String {
        switch productID {
        case small: return "small"
        case medium: return "medium"
        case large: return "large"
        default: return "unknown"
        }
    }
}

enum TipJarCopy {
    static let rowTitle = "Support the Developer"
    static let sheetTitle = "Support the Developer"
    static let footer = "Optional tip to support development. It doesn’t unlock features. Apple processes the payment."
    static let thankYou = "Thanks for supporting Puzzle Buddy."
    static let unavailable = "Tips aren’t available right now."
    static let pending = "This tip is waiting for approval."
    static let failed = "The tip didn’t go through. Nothing was charged."
}

enum TipJarError: Error, Equatable {
    case unverified
}
