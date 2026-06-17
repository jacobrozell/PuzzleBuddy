//
//  BarcodeLookupService.swift
//  Puzzle Buddy
//

import Foundation

enum BarcodeLookupService {
    private static let endpoint = "https://api.upcitemdb.com/prod/trial/lookup"
    private static var cache: [String: BarcodeProductMetadata] = [:]

    /// Looks up product metadata: local on-device cache first, then optional UPCitemdb trial API.
    static func lookup(barcode: String) async -> BarcodeProductMetadata? {
        guard let normalized = BarcodeNormalizer.normalize(barcode) else { return nil }

        if let cached = cache[normalized] {
            return cached
        }

        if let local = BarcodeMetadataCache.metadata(for: normalized) {
            cache[normalized] = local
            AppLog.shared.info(
                .puzzles,
                eventName: "barcode_lookup_succeeded",
                message: "Barcode metadata found in local cache.",
                metadata: ["has_title": local.title == nil ? "0" : "1"]
            )
            return local
        }

        guard ProductService.isBarcodeLookupEnabled else { return nil }

        guard let url = URL(string: "\(endpoint)?upc=\(normalized)") else { return nil }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                AppLog.shared.info(
                    .puzzles,
                    eventName: "barcode_lookup_failed",
                    message: "Barcode lookup returned non-success status."
                )
                return nil
            }

            let metadata = try parseResponse(data)
            if let metadata {
                cache[normalized] = metadata
                AppLog.shared.info(
                    .puzzles,
                    eventName: "barcode_lookup_succeeded",
                    message: "Barcode metadata found.",
                    metadata: ["has_title": metadata.title == nil ? "0" : "1"]
                )
            } else {
                AppLog.shared.info(
                    .puzzles,
                    eventName: "barcode_lookup_failed",
                    message: "No items in barcode lookup response."
                )
            }
            return metadata
        } catch {
            AppLog.shared.info(
                .puzzles,
                eventName: "barcode_lookup_failed",
                message: error.localizedDescription
            )
            return nil
        }
    }

    static func parseResponse(_ data: Data) throws -> BarcodeProductMetadata? {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let items = json?["items"] as? [[String: Any]], let first = items.first else {
            return nil
        }

        let title = first["title"] as? String
        let brand = first["brand"] as? String
        let images = first["images"] as? [String]
        let imageURL = images?.first.flatMap(URL.init(string:))

        return BarcodeProductMetadata.fromLookup(title: title, brand: brand, imageURL: imageURL)
    }

    #if DEBUG
    static func resetCacheForTesting() {
        cache = [:]
    }
    #endif
}
