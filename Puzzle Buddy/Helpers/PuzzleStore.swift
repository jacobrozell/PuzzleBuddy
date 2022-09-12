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

    func fetchPuzzles() {
        self.state = .fetching

        store.collection(path).getDocuments { result, error in
            guard let result = result else {
                self.state = .idle
                return
            }

            self.puzzles = result.documents.compactMap({
                self.parsePuzzle($0.data())
            })

            self.state = .done
        }
    }

    func parsePuzzle(_ data: [String: Any]) -> Puzzle {
        let p: Puzzle = .fixture()

        if let id = data["id"] as? String, let id = UUID(uuidString: id) {
            p.id = id
        } else {
            print("KeyError: id not found")
        }

        if let name = data["name"] as? String {
            p.name = name
        } else {
            print("KeyError: name not found")
        }

        if let pieces = data["pieces"] as? Int {
            p.pieces = pieces
        } else {
            print("KeyError: pieces not found")
        }

        if let rating = data["rating"] as? Double {
            p.rating = Puzzle.Rating(rawValue: rating) ?? .one
        } else {
            print("KeyError: rating not found")
        }

        if let difficulty = data["difficulty"] as? String {
            p.difficulty = Puzzle.Difficulty(rawValue: difficulty) ?? .one
        } else {
            print("KeyError: difficulty not found")
        }

        if let estimatedTimeSpent = data["estimatedTimeSpent"] as? String {
            p.estimatedTimeSpent = Puzzle.PuzzleTime(name: estimatedTimeSpent)
        } else {
            print("KeyError: estimatedTimeSpent not found")
        }

        if let completionDate = data["completionDate"] as? Timestamp {
            p.completionDate = completionDate.dateValue()
        } else {
            print("KeyError: completionDate not found")
        }

        if let status = data["status"] as? String {
            p.status = Puzzle.Status(rawValue: status) ?? .todo
        } else {
            print("KeyError: status not found")
        }

        if let imageData = data["imageData"] as? String, let data = Data(base64Encoded: imageData) {
            p.image = UIImage(data: data)
        } else {
            print("KeyError: image not found")
        }

        return p
    }

    func add(puzzle: Puzzle) throws {
        guard
            let puzzleUser = puzzleUser
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
                print("Puzzle: \(puzzle.name) updated succesfully!")
            }
        }
    }
}
