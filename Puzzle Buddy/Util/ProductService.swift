//
//  ProductService.swift
//  Puzzle Buddy
//
//  Feature flags for staged releases.
//

import Foundation

enum ProductService {
    private static let enableCollectionImportExportArgument = "-enable_collection_import_export"

    /// Live barcode scanner (VisionKit). Requires camera hardware.
    @MainActor
    static var isBarcodeScanEnabled: Bool {
        BarcodeScannerSupport.isAvailable
    }

    /// Shopping duplicate-check mode (offline, no product lookup).
    static var isShoppingModeEnabled: Bool {
        true
    }

    /// "Pick my next puzzle" random selector (1.0).
    static var isPickNextEnabled: Bool {
        true
    }

    /// IPDb CSV import and JSON/CSV export (Settings → Collection). Off for 1.0.0.
    static var isCollectionImportExportEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(enableCollectionImportExportArgument)
    }
}
