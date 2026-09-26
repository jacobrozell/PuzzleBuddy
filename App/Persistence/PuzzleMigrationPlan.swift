//
//  PuzzleMigrationPlan.swift
//  Puzzle Buddy
//

import Foundation
import SwiftData

/// SwiftData migration plan. V1 is the 1.0.0 store shape; V2 adds FriendRecord + loan fields.
///
/// Additive optional / defaulted properties use `MigrationStage.lightweight`.
///
/// Policy for agents: `docs/swiftdata-migrations.md`
enum PuzzleMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PuzzleSchemaV1.self, PuzzleSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1ToV2]
    }

    static let migrateV1ToV2 = MigrationStage.lightweight(
        fromVersion: PuzzleSchemaV1.self,
        toVersion: PuzzleSchemaV2.self
    )
}
