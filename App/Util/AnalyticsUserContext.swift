//
//  AnalyticsUserContext.swift
//  Puzzle Buddy
//

import FirebaseAnalytics
import Foundation

/// Privacy-safe user properties for retention and collection-depth segmentation.
///
/// Values are coarse enums/booleans only — never puzzle titles, brands, or barcodes.
enum AnalyticsUserContext {
    static func syncOnboardingComplete(_ complete: Bool = OnboardingStorage.isComplete) {
        setUserProperties([
            "onboarding_complete": boolString(complete)
        ])
    }

    static func syncCollection(from puzzles: [Puzzle]) {
        let completed = puzzles.filter { $0.status == .completed }.count
        setUserProperties([
            "collection_size_bucket": PuzzleAnalyticsMetadata.collectionSizeBucket(puzzles.count),
            "completed_count_bucket": PuzzleAnalyticsMetadata.completedCountBucket(completed),
            "has_completed_puzzle": boolString(completed > 0),
            "onboarding_complete": boolString(OnboardingStorage.isComplete),
        ])
    }

    static func userPropertyValues(for puzzles: [Puzzle]) -> [String: String] {
        let completed = puzzles.filter { $0.status == .completed }.count
        return [
            "collection_size_bucket": PuzzleAnalyticsMetadata.collectionSizeBucket(puzzles.count),
            "completed_count_bucket": PuzzleAnalyticsMetadata.completedCountBucket(completed),
            "has_completed_puzzle": boolString(completed > 0),
            "onboarding_complete": boolString(OnboardingStorage.isComplete),
        ]
    }

    private static func setUserProperties(_ values: [String: String]) {
        guard FirebaseBootstrap.shouldConfigure,
              FirebaseBootstrap.isAnalyticsCollectionEnabled
        else { return }

        for (name, value) in values {
            Analytics.setUserProperty(value, forName: name)
        }
    }

    private static func boolString(_ value: Bool) -> String {
        value ? "true" : "false"
    }
}
