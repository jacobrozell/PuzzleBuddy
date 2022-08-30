//
//  PuzzleStore.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/30/22.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

// MARK: - PuzzleStore
@MainActor
class PuzzleStore: ObservableObject {
    @Published var puzzles: [Puzzle] = []

    private let store = Firestore.firestore()
    private var path = ""

    let puzzleUser: PuzzleUser

    public init(user: PuzzleUser) {
        self.puzzleUser = user
        self.path = "/users/\(puzzleUser.email ?? "")/puzzles"
        self.fetchPuzzles()
    }

    func fetchPuzzles() {
        store.collection(path).getDocuments { result, error in
            guard let result = result else {
                return
            }

            self.puzzles = result.documents.compactMap({ Puzzle(name: $0.data()["name"] as! String) })
        }
    }

    func add(puzzle: Puzzle) throws {
        let puzzlesRef = store.collection(path)

        puzzlesRef.document(puzzle.name).setData([
            "name": puzzle.name,
            "pieces": puzzle.pieces,
            "owner": puzzleUser.email!
        ]) { error in
            if let error = error {
                print("Error adding Puzzle: \(error.localizedDescription)")
            } else {
                self.puzzles.append(puzzle)
            }
        }
    }

    func delete(at offsets: IndexSet) {
//        let puzzlesRef = store.collection(path).

//        let puzzlesRef = store.collection("puzzles")
        puzzles.remove(atOffsets: offsets)

//        #warning("delete on database")

    }
}
