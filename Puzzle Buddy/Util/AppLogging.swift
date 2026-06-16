//
//  AppLogging.swift
//  Puzzle Buddy
//
//  Privacy-safe logging with optional Firebase Analytics (Dart Buddy pattern).
//

import FirebaseAnalytics
import FirebaseCrashlytics
import Foundation
import os.log

// MARK: - Log levels & categories

enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum LogCategory: String, Sendable {
    case app
    case auth
    case puzzles
    case ui
}

// MARK: - App logger

protocol AppLogger: Sendable {
    func log(
        level: LogLevel,
        category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]?
    )
}

extension AppLogger {
    func debug(_ category: LogCategory, eventName: String, message: String, metadata: [String: String]? = nil) {
        log(level: .debug, category: category, eventName: eventName, message: message, metadata: metadata)
    }

    func info(_ category: LogCategory, eventName: String, message: String, metadata: [String: String]? = nil) {
        log(level: .info, category: category, eventName: eventName, message: message, metadata: metadata)
    }

    func warning(_ category: LogCategory, eventName: String, message: String, metadata: [String: String]? = nil) {
        log(level: .warning, category: category, eventName: eventName, message: message, metadata: metadata)
    }

    func error(_ category: LogCategory, eventName: String, message: String, metadata: [String: String]? = nil) {
        log(level: .error, category: category, eventName: eventName, message: message, metadata: metadata)
    }
}

// MARK: - Firebase bootstrap

enum FirebaseBootstrap {
    static var shouldConfigure: Bool {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let appID = plist["GOOGLE_APP_ID"] as? String
        else {
            return false
        }
        return !appID.contains("REPLACE_WITH")
    }

    static var isAnalyticsCollectionEnabled: Bool {
        shouldConfigure && !ProcessInfo.processInfo.arguments.contains("-disable_firebase_analytics")
    }
}

// MARK: - Analytics mapping

enum PuzzleAnalyticsEventMapping {
    private static let allowlistedEvents: Set<String> = [
        "app_bootstrap_ready",
        "user_signed_in",
        "user_signed_out",
        "user_account_created",
        "user_profile_updated",
        "puzzle_list_refreshed",
        "puzzle_added",
        "puzzle_updated",
        "puzzle_deleted",
        "puzzle_sync_failed",
        "auth_failed"
    ]

    private static let allowlistedParameterKeys: Set<String> = [
        "app_version",
        "log_category",
        "auth_provider",
        "puzzle_count",
        "puzzle_status"
    ]

    static func map(
        eventName: String,
        category: LogCategory,
        metadata: [String: String],
        appVersion: String
    ) -> (name: String, parameters: [String: Any])? {
        guard allowlistedEvents.contains(eventName) else { return nil }

        var parameters: [String: Any] = [:]
        for key in allowlistedParameterKeys {
            guard let value = metadata[key], !value.isEmpty else { continue }
            parameters[key] = String(value.prefix(100))
        }
        parameters["app_version"] = appVersion
        parameters["log_category"] = category.rawValue

        let firebaseName = eventName == "app_bootstrap_ready" ? "app_open" : eventName
        return (firebaseName, parameters)
    }
}

// MARK: - Redaction

enum LogRedaction {
    private static let blockedKeys: Set<String> = [
        "email", "uid", "password", "token", "name", "displayName"
    ]

    static func redact(_ metadata: [String: String]) -> [String: String] {
        metadata.filter { !blockedKeys.contains($0.key.lowercased()) }
    }
}

// MARK: - Default implementation

struct DefaultAppLogger: AppLogger {
    private let minimumLevel: LogLevel
    private let appVersion: String
    private let osLog = Logger(subsystem: "com.jacobrozell.Puzzle-Buddy", category: "app")

    init(minimumLevel: LogLevel, appVersion: String) {
        self.minimumLevel = minimumLevel
        self.appVersion = appVersion
    }

    func log(
        level: LogLevel,
        category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]?
    ) {
        guard level >= minimumLevel else { return }

        let redacted = LogRedaction.redact(metadata ?? [:])
        let metadataSummary = redacted.isEmpty ? "" : " \(redacted)"
        osLog.log(level: level.osLogType, "[\(category.rawValue)] \(eventName): \(message)\(metadataSummary)")

        guard level >= .info,
              FirebaseBootstrap.isAnalyticsCollectionEnabled,
              let mapped = PuzzleAnalyticsEventMapping.map(
                eventName: eventName,
                category: category,
                metadata: redacted,
                appVersion: appVersion
              )
        else {
            recordCrashlyticsLog(level: level, category: category, eventName: eventName, message: message)
            return
        }

        Analytics.logEvent(mapped.name, parameters: mapped.parameters)
        recordCrashlyticsLog(level: level, category: category, eventName: eventName, message: message)
    }

    private func recordCrashlyticsLog(
        level: LogLevel,
        category: LogCategory,
        eventName: String,
        message: String
    ) {
        guard level >= .warning,
              FirebaseBootstrap.shouldConfigure,
              !UITestSupport.isRunningUnderTest
        else { return }

        Crashlytics.crashlytics().log("[\(category.rawValue)] \(eventName): \(message)")
        if level >= .error {
            let error = NSError(
                domain: "com.jacobrozell.Puzzle-Buddy",
                code: level.rawValue,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
            Crashlytics.crashlytics().record(error: error)
        }
    }
}

private extension LogLevel {
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}

enum AppLog {
    static let shared: AppLogger = {
        #if DEBUG
        return DefaultAppLogger(minimumLevel: .debug, appVersion: Puzzle_BuddyApp.version)
        #else
        return DefaultAppLogger(minimumLevel: .info, appVersion: Puzzle_BuddyApp.version)
        #endif
    }()
}
