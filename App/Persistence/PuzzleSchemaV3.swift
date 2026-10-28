//
//  PuzzleSchemaV3.swift
//  Puzzle Buddy
//
//  Schema after the in-app timer (1.2.0).
//  Live app models are the top-level @Model types listed here.
//

import Foundation
import SwiftData

/// Version 3 schema — adds `timerAccumulatedSeconds` and `timerRunningSince` on `PuzzleRecord`.
///
/// Policy for agents: `docs/swiftdata-migrations.md`
enum PuzzleSchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 2, 0) }

    static var models: [any PersistentModel.Type] {
        [
            FriendRecord.self,
            PuzzleRecord.self,
            PuzzlePhotoRecord.self,
            PuzzleCompletionRecord.self,
        ]
    }
}
