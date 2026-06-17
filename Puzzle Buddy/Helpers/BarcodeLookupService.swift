//
//  BarcodeLookupService.swift
//  Puzzle Buddy
//

import Foundation

enum BarcodeLookupService {
    private static let endpoint = "https://api.upcitemdb.com/prod/trial/lookup"
    private static var cache: [String: BarcodeProductMetadata] = [:]

    /// Looks up product metadata: local on-device cache first, then optional UPCitemdb trial API.
    static func lookup(barcode: String) async -> BarcodeLookupResult {
        guard let normalized = BarcodeNormalizer.normalize(barcode) else {
            return .failure(.notFound)
        }

        if let cached = cache[normalized] {
            return .success(cached)
        }

        if let local = BarcodeMetadataCache.metadata(for: normalized) {
            cache[normalized] = local
            AppLog.shared.info(
                .puzzles,
                eventName: "barcode_lookup_succeeded",
                message: "Barcode metadata found in local cache.",
                metadata: ["has_title": local.title == nil ? "0" : "1"]
            )
            return .success(local)
        }

        guard ProductService.isBarcodeLookupEnabled else {
            return .empty()
        }

        return await performOnlineLookup(normalized: normalized)
    }

    private static func performOnlineLookup(normalized: String) async -> BarcodeLookupResult {
        guard let url = URL(string: "\(endpoint)?upc=\(normalized)") else {
            return .failure(.unavailable)
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                logLookupFailed(message: "Barcode lookup returned a non-HTTP response.")
                return .failure(.unavailable)
            }

            if let notice = BarcodeLookupResult.notice(forHTTPStatusCode: http.statusCode) {
                logLookupFailed(
                    message: "Barcode lookup returned status \(http.statusCode).",
                    metadata: ["status_code": "\(http.statusCode)"]
                )
                return .failure(notice)
            }

            let metadata = try parseResponse(data)
            if let metadata {
                cache[normalized] = metadata
                BarcodeMetadataCache.storeLookup(metadata, for: normalized)
                AppLog.shared.info(
                    .puzzles,
                    eventName: "barcode_lookup_succeeded",
                    message: "Barcode metadata found.",
                    metadata: ["has_title": metadata.title == nil ? "0" : "1"]
                )
                return .success(metadata)
            }

            logLookupFailed(message: "No items in barcode lookup response.")
            return .failure(.notFound)
        } catch {
            logLookupFailed(message: error.localizedDescription)
            return .failure(.unavailable)
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

    private static func logLookupFailed(message: String, metadata: [String: String] = [:]) {
        AppLog.shared.info(
            .puzzles,
            eventName: "barcode_lookup_failed",
            message: message,
            metadata: metadata
        )
    }

    #if DEBUG
    static func resetCacheForTesting() {
        cache = [:]
    }
    #endif
}
