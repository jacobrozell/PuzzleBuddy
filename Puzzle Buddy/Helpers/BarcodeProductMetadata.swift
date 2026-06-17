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
