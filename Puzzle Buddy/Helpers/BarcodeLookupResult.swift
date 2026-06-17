//
//  BarcodeLookupResult.swift
//  Puzzle Buddy
//

import Foundation

struct BarcodeLookupResult: Equatable {
    let metadata: BarcodeProductMetadata?
    let notice: Notice?

    enum Notice: Equatable {
        case rateLimited
        case unavailable
        case notFound

        var message: String {
            switch self {
            case .rateLimited:
                return "Online lookup limit reached for today. Enter details manually or try again tomorrow."
            case .unavailable:
                return "Online lookup is unavailable right now. Enter details manually."
            case .notFound:
                return "No product details found for this barcode. Enter a name below."
            }
        }
    }

    static func success(_ metadata: BarcodeProductMetadata) -> BarcodeLookupResult {
        BarcodeLookupResult(metadata: metadata, notice: nil)
    }

    static func failure(_ notice: Notice) -> BarcodeLookupResult {
        BarcodeLookupResult(metadata: nil, notice: notice)
    }

    static func empty() -> BarcodeLookupResult {
        BarcodeLookupResult(metadata: nil, notice: nil)
    }

    /// Maps HTTP status from UPCitemdb (and similar APIs) to a user-facing notice.
    static func notice(forHTTPStatusCode statusCode: Int) -> Notice? {
        if statusCode == 429 {
            return .rateLimited
        }
        if !(200...299).contains(statusCode) {
            return .unavailable
        }
        return nil
    }
}
