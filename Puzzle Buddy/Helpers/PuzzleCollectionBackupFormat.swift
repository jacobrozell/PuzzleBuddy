//
//  PuzzleCollectionBackupFormat.swift
//  Puzzle Buddy
//
//  Versioned JSON backup format for full collection restore.
//

import Foundation

enum PuzzleCollectionBackupFormat {
    /// Increment when export shape changes in a breaking or additive way.
    static let currentVersion = 2

    /// v1 — initial JSON export (metadata + hasImage flag, no embedded photos).
    /// v2 — adds `photos` with base64 JPEG payloads; explicit `backupFormatVersion`.
}

struct PuzzleExportPhotoRecord: Codable, Equatable {
    let id: String
    let sortOrder: Int
    let imageDataBase64: String?
    let createdAt: Date?
}
