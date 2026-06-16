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
    private let injectedRemoteStore: PuzzleRemoteStore?
    private let forceCloudSync: Bool
    private var path = ""

    init(
        modelContext: ModelContext,
        user: PuzzleUser? = nil,
        syncPath: String? = nil,
        remoteStore: PuzzleRemoteStore? = nil,
        forceCloudSync: Bool = false
    ) {
        self.modelContext = modelContext
        self.puzzleUser = user
        self.injectedRemoteStore = remoteStore
        self.forceCloudSync = forceCloudSync
        if let user {
            self.path = "/users/\(user.email ?? "")/puzzles"
        } else if let syncPath {
            self.path = syncPath
        }
        self.puzzles = []

        if UITestSupport.shouldSeedPuzzles {
            loadLocalPuzzles()
            UITestSupport.seedPuzzlesIfNeeded(into: self)
        }
    }

    private var usesCloudSync: Bool {
        guard !path.isEmpty, resolveRemoteStore() != nil else { return false }
        if forceCloudSync { return true }
        return puzzleUser != nil && ProductService.isCloudSyncEnabled
    }

    private func resolveRemoteStore() -> PuzzleRemoteStore? {
        if let injectedRemoteStore { return injectedRemoteStore }
        guard FirebaseBootstrap.shouldConfigure else { return nil }
        return FirestorePuzzleRemoteStore()
    }

    func fetchPuzzles() async {
        guard usesCloudSync, let remoteStore = resolveRemoteStore() else {
            loadLocalPuzzles()
            return
        }

        self.state = .fetching

        do {
            let documents = try await remoteStore.fetchDocuments(at: path)

            self.puzzles = documents.compactMap({
                Puzzle.fromData($0)
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
        guard usesCloudSync, let remoteStore = resolveRemoteStore() else {
            try addLocally(puzzle: puzzle)
            return
        }

        Task {
            do {
                try await remoteStore.setDocument(
                    at: path,
                    id: puzzle.id.uuidString,
                    data: puzzle.getDataFields()
                )
                try self.addLocally(puzzle: puzzle)
                AppLog.shared.info(
                    .puzzles,
                    eventName: "puzzle_added",
                    message: "Puzzle saved.",
                    metadata: ["puzzle_status": puzzle.status.rawValue]
                )
            } catch {
                AppLog.shared.error(.puzzles, eventName: "puzzle_sync_failed", message: error.localizedDescription)
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
        let puzzlesToDelete = offsets.map { puzzles[$0] }

        if usesCloudSync, let remoteStore = resolveRemoteStore() {
            Task {
                for puzzle in puzzlesToDelete {
                    do {
                        try await remoteStore.deleteDocument(at: path, id: puzzle.id.uuidString)
                    } catch {
                        AppLog.shared.error(.puzzles, eventName: "puzzle_sync_failed", message: error.localizedDescription)
                    }
                }
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
        if usesCloudSync, let remoteStore = resolveRemoteStore() {
            Task {
                do {
                    try await remoteStore.updateDocument(
                        at: path,
                        id: puzzle.id.uuidString,
                        data: puzzle.getDataFields()
                    )
                    self.updateLocally(puzzle: puzzle)
                    AppLog.shared.info(
                        .puzzles,
                        eventName: "puzzle_updated",
                        message: "Puzzle updated.",
                        metadata: ["puzzle_status": puzzle.status.rawValue]
                    )
                } catch {
                    AppLog.shared.error(.puzzles, eventName: "puzzle_sync_failed", message: error.localizedDescription)
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
