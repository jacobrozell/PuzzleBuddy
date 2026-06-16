//
//  PuzzleStore.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 8/30/22.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftData
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
    private let modelContext: ModelContext
    private var path = ""

    init(modelContext: ModelContext, user: PuzzleUser? = nil) {
        self.modelContext = modelContext
        self.puzzleUser = user
        if let user {
            self.path = "/users/\(user.email ?? "")/puzzles"
        }
        self.puzzles = []
    }

    private var usesCloudSync: Bool {
        puzzleUser != nil && ProductService.isCloudSyncEnabled
    }

    private var firestore: Firestore? {
        guard FirebaseBootstrap.shouldConfigure else { return nil }
        return Firestore.firestore()
    }

    func fetchPuzzles() async {
        guard usesCloudSync, let firestore else {
            loadLocalPuzzles()
            return
        }

        self.state = .fetching

        do {
            let documents = try await firestore.collection(path).getDocuments()

            self.puzzles = documents.documents.compactMap({
                Puzzle.fromData($0.data())
            })

            self.state = .done
            AppLog.shared.info(
                .puzzles,
                eventName: "puzzle_list_refreshed",
                message: "Fetched puzzles.",
                metadata: ["puzzle_count": "\(self.puzzles.count)"]
            )

        } catch {
            self.state = .idle
            AppLog.shared.warning(.puzzles, eventName: "puzzle_sync_failed", message: error.localizedDescription)
            return
        }
    }

    func add(puzzle: Puzzle) throws {
        guard usesCloudSync, let firestore else {
            try addLocally(puzzle: puzzle)
            return
        }

        let puzzlesRef = firestore.collection(path)
        puzzlesRef.document(puzzle.id.uuidString).setData(puzzle.getDataFields()) { error in
            if let error = error {
                AppLog.shared.error(.puzzles, eventName: "puzzle_sync_failed", message: error.localizedDescription)
            } else {
                do {
                    try self.addLocally(puzzle: puzzle)
                } catch {
                    AppLog.shared.error(.puzzles, eventName: "puzzle_sync_failed", message: error.localizedDescription)
                }
                AppLog.shared.info(
                    .puzzles,
                    eventName: "puzzle_added",
                    message: "Puzzle saved.",
                    metadata: ["puzzle_status": puzzle.status.rawValue]
                )
            }
        }
    }

    private func addLocally(puzzle: Puzzle) throws {
        let record = PuzzleRecord(from: puzzle)
        modelContext.insert(record)
        try modelContext.save()
        puzzles.append(puzzle)
        AppLog.shared.info(
            .puzzles,
            eventName: "puzzle_added",
            message: "Puzzle saved.",
            metadata: ["puzzle_status": puzzle.status.rawValue]
        )
    }

    func delete(at offsets: IndexSet) {
        if usesCloudSync, let firestore {
            let puzzlesRef = firestore.collection(path)

            for object in offsets {
                let puzzle = self.puzzles[object]
                puzzlesRef.document(puzzle.id.uuidString).delete()
            }
        }

        deleteLocally(at: offsets)
        AppLog.shared.info(.puzzles, eventName: "puzzle_deleted", message: "Puzzle deleted.")
    }

    private func deleteLocally(at offsets: IndexSet) {
        for index in offsets {
            let puzzle = puzzles[index]
            if let record = fetchRecord(id: puzzle.id) {
                modelContext.delete(record)
            }
        }
        puzzles.remove(atOffsets: offsets)
        try? modelContext.save()
    }

    func update(puzzle: Puzzle) {
        if usesCloudSync, let firestore {
            firestore.collection(path).document(puzzle.id.uuidString).updateData(puzzle.getDataFields()) { error in
                if let error = error {
                    AppLog.shared.error(.puzzles, eventName: "puzzle_sync_failed", message: error.localizedDescription)
                } else {
                    self.updateLocally(puzzle: puzzle)
                    AppLog.shared.info(
                        .puzzles,
                        eventName: "puzzle_updated",
                        message: "Puzzle updated.",
                        metadata: ["puzzle_status": puzzle.status.rawValue]
                    )
                }
            }
            return
        }

        updateLocally(puzzle: puzzle)
        AppLog.shared.info(
            .puzzles,
            eventName: "puzzle_updated",
            message: "Puzzle updated.",
            metadata: ["puzzle_status": puzzle.status.rawValue]
        )
    }

    private func loadLocalPuzzles() {
        do {
            let descriptor = FetchDescriptor<PuzzleRecord>(
                sortBy: [SortDescriptor(\.completionDate, order: .reverse)]
            )
            puzzles = try modelContext.fetch(descriptor).map { $0.toPuzzle() }
            state = .done
            AppLog.shared.info(
                .puzzles,
                eventName: "puzzle_list_refreshed",
                message: "Loaded local puzzles.",
                metadata: ["puzzle_count": "\(puzzles.count)"]
            )
        } catch {
            state = .idle
            AppLog.shared.warning(.puzzles, eventName: "puzzle_sync_failed", message: error.localizedDescription)
        }
    }

    private func updateLocally(puzzle: Puzzle) {
        guard let record = fetchRecord(id: puzzle.id) else { return }
        record.apply(from: puzzle)
        if let index = puzzles.firstIndex(where: { $0.id == puzzle.id }) {
            puzzles[index] = puzzle
        }
        try? modelContext.save()
    }

    private func fetchRecord(id: UUID) -> PuzzleRecord? {
        let puzzleID = id
        var descriptor = FetchDescriptor<PuzzleRecord>(
            predicate: #Predicate { $0.id == puzzleID }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }
}
