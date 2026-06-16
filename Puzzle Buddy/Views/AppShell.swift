//
//  AppShell.swift
//  Puzzle Buddy
//

import SwiftData
import SwiftUI

/// Root shell: branded splash → main app content.
struct AppShell: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSplash = !AppInfo.isUITesting

    let modelContext: ModelContext

    var body: some View {
        Group {
            if UITestSupport.isRunningUnderTest || UITestSupport.isBypassAuthEnabled {
                RootView(modelContext: modelContext)
            } else {
                ZStack {
                    RootView(modelContext: modelContext)

                    if showSplash {
                        SplashView()
                            .transition(.opacity)
                            .zIndex(1)
                    }
                }
                .task(id: showSplash) {
                    guard showSplash else { return }
                    // Brief branded moment so the loader reads as intentional, not a flash.
                    try? await Task.sleep(for: .milliseconds(1_400))
                    if reduceMotion {
                        showSplash = false
                    } else {
                        withAnimation(.easeOut(duration: 0.4)) {
                            showSplash = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    AppShell(modelContext: PreviewSupport.modelContext)
        .environmentObject(FirebaseAuthProvider())
}
