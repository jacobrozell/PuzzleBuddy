//
//  BarcodeProductMetadata.swift
//  Puzzle Buddy
//

import Foundation

struct BarcodeProductMetadata: Equatable {
    let title: String?
    let brand: String?
    let pieces: Int?
    let imageURL: URL?
    let source: String

    var suggestedName: String? {
        BarcodeTitleParser.cleanedTitle(title)
    }

    var suggestedPieces: Int? {
        pieces ?? BarcodeTitleParser.pieces(from: title)
    }

    var lookupSourceLabel: String? {
        switch source {
        case "local_cache":
            return "From your saved puzzles"
        case "upcitemdb":
            return "From online product lookup"
        default:
            return nil
        }
    }

    static func fromLookup(title: String?, brand: String?, imageURL: URL?) -> BarcodeProductMetadata {
        BarcodeProductMetadata(
            title: BarcodeTitleParser.cleanedTitle(title),
            brand: BarcodeTitleParser.cleanedTitle(brand),
            pieces: BarcodeTitleParser.pieces(from: title),
            imageURL: imageURL,
            source: "upcitemdb"
        )
    }
}
