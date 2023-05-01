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

            self.puzzles = result.documents.compactMap({
                Puzzle(
                    name: $0.data()["name"] as! String,
                    pieces: $0.data()["pieces"] as! Int,
                    rating: .init(rawValue: $0.data()["rating"] as! Double) ?? .three,
                    difficulty: .init(rawValue: $0.data()["difficulty"] as! String) ?? .three,
                    estimatedTimeSpent: .init(name: $0.data()["estimatedTimeSpent"] as! String),
                    completionDate: ($0.data()["completionDate"] as! Timestamp).dateValue(),
                    status: Puzzle.Status(rawValue: $0.data()["status"] as! String) ?? .todo
                )
            })
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
            "rating": puzzle.rating.rawValue,
            "difficulty": puzzle.difficulty.rawValue,
            "completionDate": puzzle.completionDate,
            "estimatedTimeSpent": puzzle.estimatedTimeSpent?.toName() ?? "",
            "status": puzzle.status.rawValue,
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

    func update(puzzle: Puzzle) {
        print("TODO")
    }
}
