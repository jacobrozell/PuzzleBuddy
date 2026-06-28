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
}
