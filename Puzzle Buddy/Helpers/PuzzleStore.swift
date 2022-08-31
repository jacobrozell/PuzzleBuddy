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

    let puzzleUser: PuzzleUser?

    private let store = Firestore.firestore()
    private var path = ""

    public init() {
        self.puzzleUser = nil
        self.puzzles = []
    }

    public init(user: PuzzleUser) {
        self.puzzleUser = user
        self.path = "/users/\(puzzleUser!.email ?? "")/puzzles"
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
        guard
            let puzzleUser = puzzleUser
        else {
            self.addLocally(puzzle: puzzle)
            return
        }

        let puzzlesRef = store.collection(path)

        puzzlesRef.document(puzzle.name).setData([
            "name": puzzle.name,
            "pieces": puzzle.pieces,
            "rating": puzzle.rating?.rawValue ?? "",
            "dificulty": puzzle.difficulty?.rawValue ?? "",
            "completionDate": puzzle.completionDate.ISO8601Format(),
            "estimatedTimeSpent": puzzle.estimatedTimeSpent?.toName() ?? "",
            "owner": puzzleUser.email!
        ]) { error in
            if let error = error {
                print("Error adding Puzzle: \(error.localizedDescription)")
            } else {
                self.addLocally(puzzle: puzzle)
            }
        }
    }

    private func addLocally(puzzle: Puzzle) {
        self.puzzles.append(puzzle)
    }

    func delete(at offsets: IndexSet) {
        guard let _ = puzzleUser else {
            deleteLocally(at: offsets)
            return
        }

        let puzzlesRef = store.collection(path)

        for this in offsets {
            let puzzle = self.puzzles[this]
            puzzlesRef.document(puzzle.name).delete()
            deleteLocally(at: offsets)
        }
    }

    private func deleteLocally(at offsets: IndexSet) {
        puzzles.remove(atOffsets: offsets)
    }
}
