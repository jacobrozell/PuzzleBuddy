//
//  PuzzleCollectionBackupFormat.swift
//  Puzzle Buddy
//
//  Versioned JSON backup format for full collection restore.
//

import Foundation

enum PuzzleCollectionBackupFormat {
    /// Increment when export shape changes in a breaking way. Additive fields stay on the same version.
    static let currentVersion = 1

    /// v1 (1.0 ship) — full metadata, embedded photos (base64 JPEG), completion history, `backupFormatVersion`.
}

struct PuzzleExportPhotoRecord: Codable, Equatable {
    let id: String
    let sortOrder: Int
    let imageDataBase64: String?
    let createdAt: Date?
}
