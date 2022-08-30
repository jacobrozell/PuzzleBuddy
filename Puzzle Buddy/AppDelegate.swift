//
//  AppDelegate.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/30/22.
//

import UIKit
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

    FirebaseApp.configure()
    return true
  }
}
