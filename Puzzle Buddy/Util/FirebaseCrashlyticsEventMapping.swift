//
//  FirebaseCrashlyticsEventMapping.swift
//  Puzzle Buddy
//

import Foundation

enum FirebaseCrashlyticsEventMapping {
    private static let errorDomain = "com.jacobrozell.Puzzle-Buddy.logger"

    private static let allowlistedLogEvents: Set<String> = [
        "puzzle_sync_failed",
        "model_container_load_failed",
        "model_container_reset_failed",
        "demo_data_seed_failed"
    ]

    /// Stable NSError codes for Crashlytics grouping (documented in unit tests).
    static let eventCodes: [String: Int] = [
        "puzzle_sync_failed": 2001,
        "model_container_load_failed": 2002,
        "model_container_reset_failed": 2003,
        "demo_data_seed_failed": 2004
    ]

    private static let allowlistedParameterKeys: Set<String> = [
        "app_version",
        "log_category",
        "event_name",
        "puzzle_count",
        "puzzle_status",
        "format"
    ]

    static func nonFatalError(
        level: LogLevel,
        category: LogCategory,
        eventName: String,
        metadata: [String: String],
        appVersion: String
    ) -> NSError? {
        guard level >= .error,
              allowlistedLogEvents.contains(eventName),
              let code = eventCodes[eventName]
        else {
            return nil
        }

        var userInfo = sanitizedParameters(from: metadata)
        userInfo["log_category"] = category.rawValue
        userInfo["event_name"] = eventName
        if !appVersion.isEmpty {
            userInfo["app_version"] = appVersion
        }

        return NSError(domain: errorDomain, code: code, userInfo: userInfo)
    }

    private static func sanitizedParameters(from metadata: [String: String]) -> [String: String] {
        metadata.reduce(into: [:]) { result, pair in
            guard allowlistedParameterKeys.contains(pair.key), !pair.value.isEmpty else { return }
            result[pair.key] = String(pair.value.prefix(100))
        }
    }
}
