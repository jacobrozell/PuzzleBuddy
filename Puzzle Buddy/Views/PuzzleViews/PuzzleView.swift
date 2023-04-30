//
//  ContentView.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/12/22.
//

import FirebaseAuth
import SwiftUI

// MARK: - ContentView
struct PuzzleView: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @StateObject var ps: PuzzleStore

    /// User init
    init(user: PuzzleUser) {
        _ps = StateObject(wrappedValue: PuzzleStore(user: user))
    }

    var body: some View {
        PuzzleTabbar(ps: ps)
            .task {
                if ps.puzzles.isEmpty {
                    await ps.fetchPuzzles()
                }
            }
    }
}

// MARK: - Previews
//struct PuzzleView_Previews: PreviewProvider {
//    static var previews: some View {
//        PuzzleView()
//    }
//}
