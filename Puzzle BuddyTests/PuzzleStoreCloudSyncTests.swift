//
//  PuzzleStoreCloudSyncTests.swift
//  Puzzle BuddyTests
//

import SwiftData
import XCTest
@testable import Puzzle_Buddy

@MainActor
final class PuzzleStoreCloudSyncTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var remoteStore: InMemoryPuzzleRemoteStore!

    override func setUpWithError() throws {
        container = try ModelContainer(
            for: PuzzleRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
        remoteStore = InMemoryPuzzleRemoteStore()
    }

    func testFetchPuzzlesLoadsFromRemoteStore() async throws {
        let puzzle = Puzzle.fixture(name: "Cloud", pieces: 500)
        try await remoteStore.setDocument(
            at: "users/test@example.com/puzzles",
            id: puzzle.id.uuidString,
            data: puzzle.getDataFields()
        )

        let store = makeCloudStore()
        await store.fetchPuzzles()

        XCTAssertEqual(store.state, .done)
        XCTAssertEqual(store.puzzles.count, 1)
        XCTAssertEqual(store.puzzles.first?.name, "Cloud")
    }

    func testAddWritesToRemoteStoreAndLocalCache() async throws {
        let store = makeCloudStore()
        let puzzle = Puzzle.fixture(name: "Synced", pieces: 750)
        try store.add(puzzle: puzzle)
        try await waitForRemoteWrite()

        let remoteDocs = try await remoteStore.fetchDocuments(at: "users/test@example.com/puzzles")
        XCTAssertEqual(remoteDocs.count, 1)
        XCTAssertEqual(remoteDocs.first?["name"] as? String, "Synced")
        XCTAssertEqual(store.puzzles.count, 1)
    }

    func testUpdateWritesToRemoteStore() async throws {
        let store = makeCloudStore()
        var puzzle = Puzzle.fixture(name: "Before", pieces: 100)
        try await remoteStore.setDocument(
            at: "users/test@example.com/puzzles",
            id: puzzle.id.uuidString,
            data: puzzle.getDataFields()
        )
        await store.fetchPuzzles()

        puzzle.name = "After"
        try store.update(puzzle: puzzle)
        try await waitForRemoteWrite()

        let remoteDocs = try await remoteStore.fetchDocuments(at: "users/test@example.com/puzzles")
        XCTAssertEqual(remoteDocs.first?["name"] as? String, "After")
    }

    func testDeleteRemovesRemoteDocument() async throws {
        let store = makeCloudStore()
        let puzzle = Puzzle.fixture(name: "Remove", pieces: 300)
        try await remoteStore.setDocument(
            at: "users/test@example.com/puzzles",
            id: puzzle.id.uuidString,
            data: puzzle.getDataFields()
        )
        await store.fetchPuzzles()

        store.delete(at: IndexSet(integer: 0))
        try await waitForRemoteWrite()

        let remoteDocs = try await remoteStore.fetchDocuments(at: "users/test@example.com/puzzles")
        XCTAssertTrue(remoteDocs.isEmpty)
        XCTAssertTrue(store.puzzles.isEmpty)
    }

    func testFetchFallsBackToIdleOnRemoteError() async {
        remoteStore.shouldFailFetch = true
        let store = makeCloudStore()

        await store.fetchPuzzles()

        XCTAssertEqual(store.state, .idle)
        XCTAssertTrue(store.puzzles.isEmpty)
    }

    private func makeCloudStore() -> PuzzleStore {
        PuzzleStore(
            modelContext: context,
            syncPath: "users/test@example.com/puzzles",
            remoteStore: remoteStore,
            forceCloudSync: true
        )
    }

    private func waitForRemoteWrite() async throws {
        for _ in 0 ..< 20 {
            try await Task.sleep(for: .milliseconds(25))
            if remoteStore.pendingWrites == 0 { return }
        }
        XCTFail("Timed out waiting for remote write")
    }
}

// MARK: - In-memory remote store for unit tests

final class InMemoryPuzzleRemoteStore: PuzzleRemoteStore, @unchecked Sendable {
    private var documents: [String: [String: [String: Any]]] = [:]
    private let lock = NSLock()
    var shouldFailFetch = false
    private(set) var pendingWrites = 0

    func fetchDocuments(at path: String) async throws -> [[String: Any]] {
        if shouldFailFetch {
            throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "fetch failed"])
        }
        lock.lock()
        defer { lock.unlock() }
        return Array(documents[path, default: [:]].values)
    }

    func setDocument(at path: String, id: String, data: [String: Any]) async throws {
        lock.lock()
        pendingWrites += 1
        documents[path, default: [:]][id] = data
        pendingWrites -= 1
        lock.unlock()
    }

    func updateDocument(at path: String, id: String, data: [String: Any]) async throws {
        try await setDocument(at: path, id: id, data: data)
    }

    func deleteDocument(at path: String, id: String) async throws {
        lock.lock()
        pendingWrites += 1
        documents[path]?[id] = nil
        pendingWrites -= 1
        lock.unlock()
    }
}
