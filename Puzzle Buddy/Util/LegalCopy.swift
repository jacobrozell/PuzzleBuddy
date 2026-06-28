//
//  LegalCopy.swift
//  Puzzle Buddy
//

import Foundation

/// Trademark and affiliation disclaimers (IPDb-inspired; see docs/spec-brand-disclaimer.md).
enum LegalCopy {
    static let brandTrademarkDisclaimer = """
    All brand names and logos are trademarks of their respective owners. Their use in Puzzle Buddy is for identification and personal cataloging only.

    Puzzle Buddy is not affiliated with, endorsed by, or sponsored by any puzzle manufacturer or retailer.
    """

    static let ipdbImportDisclaimer = """
    Puzzle Buddy is not affiliated with IPDb. Imported titles and brands come from your own export and are stored only in your personal collection on this device.
    """

    static let barcodeScanDisclaimer = """
    A scanned barcode is only a starting point. Puzzle Buddy may suggest a title, brand, or piece count from a previous entry with the same barcode, and that data can be wrong or cleaned up incorrectly. Always review and edit before saving.
    """
}
