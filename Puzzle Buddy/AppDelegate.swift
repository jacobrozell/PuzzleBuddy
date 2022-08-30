//
//  AppDelegate.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/30/22.
//

import FirebaseCore
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool
    {
        FirebaseApp.configure()
        return true
    }
}
