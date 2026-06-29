//
//  AppDelegate.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/30/22.
//

import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MarketingSnapshotBootstrap.prepareLaunchStateIfNeeded()
        SnapshotOrientationLock.configureFromLaunchArguments()

        guard FirebaseBootstrap.shouldConfigure, !UITestSupport.isRunningUnderTest else {
            return true
        }

        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(FirebaseBootstrap.isAnalyticsCollectionEnabled)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(
            FirebaseBootstrap.isCrashlyticsCollectionEnabled
        )

        return true
    }

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        SnapshotOrientationLock.mask
    }
}
