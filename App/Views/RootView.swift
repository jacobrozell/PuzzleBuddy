//
//  RootView.swift
//  Puzzle Buddy
//

import SwiftData
import SwiftUI

struct RootView: View {
    let modelContext: ModelContext
    @State private var showOnboarding = !OnboardingStorage.isComplete

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
            } else {
                PuzzleView(modelContext: modelContext)
            }
        }
        .task {
            AppLog.shared.info(.app, eventName: "app_bootstrap_ready", message: "Puzzle Buddy launched.")
        }
    }
}
