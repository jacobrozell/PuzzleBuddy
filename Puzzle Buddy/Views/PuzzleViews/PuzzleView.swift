//
//  ContentView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/12/22.
//

import SwiftData
import SwiftUI

// MARK: - ContentView
struct PuzzleView: View {
    @StateObject var ps: PuzzleStore

    init(modelContext: ModelContext) {
        _ps = StateObject(wrappedValue: PuzzleStore(modelContext: modelContext))
    }

    var body: some View {
        PuzzleTabbar(ps: ps)
            .task {
                if MarketingSnapshotBootstrap.shouldResetCollection {
                    try? ps.clearAllPuzzles()
                }
                if UITestSupport.shouldSeedPuzzles, ps.puzzles.isEmpty {
                    try? ps.loadDemoPuzzles()
                } else if ps.puzzles.isEmpty {
                    await ps.fetchPuzzles()
                }
            }
    }
}

// MARK: - Previews
struct PuzzleView_Previews: PreviewProvider {
    static var previews: some View {
        PuzzleView(modelContext: PreviewSupport.modelContext)
    }
}
