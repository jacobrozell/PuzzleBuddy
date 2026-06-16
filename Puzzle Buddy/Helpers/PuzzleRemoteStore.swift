//
//  PuzzleRemoteStore.swift
//  Puzzle Buddy
//
//  Abstraction for Firestore puzzle sync (enables unit tests without emulator).
//

import FirebaseFirestore
import Foundation

protocol PuzzleRemoteStore: Sendable {
    func fetchDocuments(at path: String) async throws -> [[String: Any]]
    func setDocument(at path: String, id: String, data: [String: Any]) async throws
    func updateDocument(at path: String, id: String, data: [String: Any]) async throws
    func deleteDocument(at path: String, id: String) async throws
}

struct FirestorePuzzleRemoteStore: PuzzleRemoteStore {
    private let firestore: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    func fetchDocuments(at path: String) async throws -> [[String: Any]] {
        let snapshot = try await firestore.collection(path).getDocuments()
        return snapshot.documents.map { $0.data() }
    }

    func setDocument(at path: String, id: String, data: [String: Any]) async throws {
        try await firestore.collection(path).document(id).setData(data)
    }

    func updateDocument(at path: String, id: String, data: [String: Any]) async throws {
        try await firestore.collection(path).document(id).updateData(data)
    }

    func deleteDocument(at path: String, id: String) async throws {
        try await firestore.collection(path).document(id).delete()
    }
}
