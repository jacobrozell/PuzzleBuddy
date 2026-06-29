//
//  BarcodeScanFeedback.swift
//  Puzzle Buddy
//

import UIKit

enum BarcodeScanFeedback {
    static func duplicateFound() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func scanAccepted() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func invalidScan(announcement: String) {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}
