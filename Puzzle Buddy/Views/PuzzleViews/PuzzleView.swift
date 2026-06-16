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

    init(modelContext: ModelContext, user: PuzzleUser? = nil) {
        _ps = StateObject(wrappedValue: PuzzleStore(modelContext: modelContext, user: user))
    }

    var body: some View {
        PuzzleTabbar(ps: ps)
            .onAppear {
                UITestSupport.seedPuzzlesIfNeeded(into: ps)
            }
            .task {
                UITestSupport.seedPuzzlesIfNeeded(into: ps)
                if ps.puzzles.isEmpty {
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
