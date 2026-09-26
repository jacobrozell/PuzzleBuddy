//
//  PuzzleSchemaV2.swift
//  Puzzle Buddy
//
//  Schema after On loan + FriendRecord (first post–1.0.0 store shape change).
//  Live app models are the top-level @Model types listed here.
//

import Foundation
import SwiftData

/// Version 2 schema — adds `FriendRecord` and loan fields on `PuzzleRecord`.
///
/// Policy for agents: `docs/swiftdata-migrations.md`
enum PuzzleSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 1, 0) }

    static var models: [any PersistentModel.Type] {
        [
            FriendRecord.self,
            PuzzleRecord.self,
            PuzzlePhotoRecord.self,
            PuzzleCompletionRecord.self,
        ]
    }
}
