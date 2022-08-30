//
//  PuzzleStore.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/30/22.
//

import FirebaseFirestore
import SwiftUI

// MARK: - PuzzleStore
@MainActor
class PuzzleStore: ObservableObject {
    @Published var puzzles: [Puzzle] = [.fixture(), .fixture()]
    let user: PuzzleUser

    init(user: PuzzleUser) {
        self.user = user
    }

    func fetchPuzzles() {
//        Firestore.firestore().
    }

    func delete(at offsets: IndexSet) {
        puzzles.remove(atOffsets: offsets)
    }
}
