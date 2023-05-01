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
    enum PuzzleStoreState {
        case idle
        case fetching
        case done
    }

    @Published var puzzles: [Puzzle] = []
    @Published var state: PuzzleStoreState = .idle

    let puzzleUser: PuzzleUser?

    private let store = Firestore.firestore()
    private var path = ""

    public init() {
        self.puzzleUser = nil
        self.puzzles = []
    }

    public init(user: PuzzleUser) {
        self.puzzleUser = user
        self.path = "/users/\(user.email ?? "")/puzzles"
    }

    func fetchPuzzles() async {
        self.state = .fetching

        do {
            let documents = try await store.collection(path).getDocuments()

            self.puzzles = documents.documents.compactMap({
                Puzzle.fromData($0.data())
            })

            self.state = .done

        } catch {
            self.state = .idle
            return
        }
    }

    func add(puzzle: Puzzle) throws {
        guard
            let _ = puzzleUser
        else {
            self.addLocally(puzzle: puzzle)
            return
        }

        let puzzlesRef = store.collection(path)
        puzzlesRef.document(puzzle.id.uuidString).setData(puzzle.getDataFields()) { error in
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

        for object in offsets {
            let puzzle = self.puzzles[object]
            puzzlesRef.document(puzzle.id.uuidString).delete()
        }

        deleteLocally(at: offsets)
    }

    private func deleteLocally(at offsets: IndexSet) {
        puzzles.remove(atOffsets: offsets)
    }

    func update(puzzle: Puzzle) {
        store.collection(path).document(puzzle.id.uuidString).updateData(puzzle.getDataFields()) { error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                // Update locally
                if let index = self.puzzles.firstIndex(where: { $0.id == puzzle.id }) {
                    self.puzzles[index] = puzzle
                    print("Puzzle: \(puzzle.name) updated succesfully!")
                } else {
                    preconditionFailure("Couldn't find index for puzzle")
                }
            }
        }
    }
}
