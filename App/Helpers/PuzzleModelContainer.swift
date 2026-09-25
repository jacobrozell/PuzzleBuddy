//
//  PuzzleModelContainer.swift
//  Puzzle Buddy
//

import Foundation
import SwiftData
import UIKit

@MainActor
enum PuzzleModelContainer {
    static var currentSchema: Schema {
        Schema([
            FriendRecord.self,
            PuzzleRecord.self,
            PuzzlePhotoRecord.self,
            PuzzleCompletionRecord.self,
        ])
    }

    /// Versioned schema used for on-disk opens with `PuzzleMigrationPlan`.
    static var versionedSchema: Schema {
        Schema(versionedSchema: PuzzleSchemaV2.self)
    }

    /// 1.0.0 production opener: unversioned three-model schema (no FriendRecord, no plan).
    /// Nested V1 types freeze the shipped property set.
    static var unversionedV1Schema: Schema {
        Schema([
            PuzzleSchemaV1.PuzzleRecord.self,
            PuzzleSchemaV1.PuzzlePhotoRecord.self,
            PuzzleSchemaV1.PuzzleCompletionRecord.self,
        ])
    }

    /// In-memory container for previews, UI tests, and unit tests.
    /// Opens the current schema without a migration plan (fresh store every time).
    static func makeInMemory() -> ModelContainer {
        let configuration = ModelConfiguration(schema: currentSchema, isStoredInMemoryOnly: true)
        do {
            UserPreferences.isRunningInEphemeralStore = true
            return try ModelContainer(for: currentSchema, configurations: [configuration])
        } catch {
            fatalError("Could not create in-memory ModelContainer: \(error)")
        }
    }

    /// In-memory container that uses the production versioned schema + plan.
    static func makeInMemoryVersioned() -> ModelContainer {
        let configuration = ModelConfiguration(schema: versionedSchema, isStoredInMemoryOnly: true)
        do {
            UserPreferences.isRunningInEphemeralStore = true
            return try ModelContainer(
                for: versionedSchema,
                migrationPlan: PuzzleMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Could not create versioned in-memory ModelContainer: \(error)")
        }
    }

    static func makePersistent() -> ModelContainer {
        if UITestSupport.isRunningUnderTest {
            return makeInMemory()
        }

        let configuration = ModelConfiguration(schema: versionedSchema, isStoredInMemoryOnly: false)
        return openPersistentStore(at: configuration.url)
    }

    /// Opens a versioned V2 store at `url`. Used by disk-migration tests.
    static func makeVersionedPersistent(url: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: versionedSchema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(
            for: versionedSchema,
            migrationPlan: PuzzleMigrationPlan.self,
            configurations: [configuration]
        )
    }

    /// Writes a 1.0.0-shaped unversioned store (nested V1 models, no plan).
    static func makeUnversionedV1Persistent(url: URL) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: unversionedV1Schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: unversionedV1Schema, configurations: [configuration])
    }

    static func openPersistentStore(at url: URL) -> ModelContainer {
        do {
            UserPreferences.isRunningInEphemeralStore = false
            return try makeVersionedPersistent(url: url)
        } catch {
            AppLog.shared.warning(
                .puzzles,
                eventName: "model_container_load_failed",
                message: error.localizedDescription
            )
            do {
                let migrated = try migrateUnversionedStore(url: url)
                AppLog.shared.info(
                    .puzzles,
                    eventName: "model_container_unversioned_migrated",
                    message: "Preserved an unversioned 1.0.0 store as V2."
                )
                UserPreferences.isRunningInEphemeralStore = false
                return migrated
            } catch {
                AppLog.shared.warning(
                    .puzzles,
                    eventName: "model_container_unversioned_migrate_failed",
                    message: error.localizedDescription
                )
                do {
                    return try recreatePersistentContainer(url: url)
                } catch {
                    AppLog.shared.warning(
                        .puzzles,
                        eventName: "model_container_reset_failed",
                        message: error.localizedDescription
                    )
                    AppLog.shared.error(
                        .puzzles,
                        eventName: "model_container_ephemeral_fallback",
                        message: "Using in-memory store; changes will not persist."
                    )
                    return makeInMemory()
                }
            }
        }
    }

    /// Copies an unversioned 1.0.0 store into a fresh V2 store at the same URL.
    /// Does **not** call `markStoreWasReset()` — the collection is preserved.
    static func migrateUnversionedStore(url: URL) throws -> ModelContainer {
        let snapshot = try snapshotUnversionedV1Store(url: url)
        try removeStoreFiles(at: url)
        let container = try makeVersionedPersistent(url: url)
        let context = container.mainContext
        for puzzle in snapshot {
            context.insert(PuzzleRecord(from: puzzle))
            for photo in puzzle.photos {
                context.insert(PuzzlePhotoRecord(from: photo, puzzleID: puzzle.id))
            }
            for completion in puzzle.completions {
                context.insert(PuzzleCompletionRecord(from: completion, puzzleID: puzzle.id))
            }
        }
        try context.save()
        return container
    }

    private static func snapshotUnversionedV1Store(url: URL) throws -> [Puzzle] {
        var puzzles: [Puzzle] = []
        try autoreleasepool {
            let container = try makeUnversionedV1Persistent(url: url)
            let context = container.mainContext
            let records = try context.fetch(FetchDescriptor<PuzzleSchemaV1.PuzzleRecord>())
            let photos = try context.fetch(FetchDescriptor<PuzzleSchemaV1.PuzzlePhotoRecord>())
            let completions = try context.fetch(FetchDescriptor<PuzzleSchemaV1.PuzzleCompletionRecord>())
            puzzles = records.map { record in
                puzzle(fromV1: record, photos: photos, completions: completions)
            }
        }
        return puzzles
    }

    private static func puzzle(
        fromV1 record: PuzzleSchemaV1.PuzzleRecord,
        photos: [PuzzleSchemaV1.PuzzlePhotoRecord],
        completions: [PuzzleSchemaV1.PuzzleCompletionRecord]
    ) -> Puzzle {
        var puzzle = Puzzle(
            name: record.name,
            pieces: record.pieces,
            rating: Puzzle.Rating(rawValue: record.rating) ?? .none,
            difficulty: Puzzle.Difficulty(rawValue: record.difficulty) ?? .none,
            estimatedTimeSpent: Puzzle.PuzzleTime(
                hours: record.estimatedTimeHours,
                minutes: record.estimatedTimeMinutes
            ),
            completionDate: record.completionDate,
            status: Puzzle.Status(rawValue: record.status) ?? .todo,
            startDate: record.startDate,
            hasMissingPieces: record.hasMissingPieces,
            notes: record.notes,
            source: record.source,
            purchaseLocation: record.purchaseLocation,
            releaseYear: record.releaseYear,
            puzzleType: PuzzleType(rawValue: record.puzzleType) ?? .none,
            material: PuzzleMaterial(rawValue: record.material) ?? .none,
            disposition: PuzzleDisposition(rawValue: record.disposition) ?? .none,
            progressPercent: record.progressPercent,
            purchasePrice: record.purchasePrice,
            purchaseCurrencyCode: record.purchaseCurrencyCode,
            puzzleShape: PuzzleShape(rawValue: record.puzzleShape) ?? .none,
            cutType: PuzzleCutType(rawValue: record.cutType) ?? .none,
            dimensionsText: record.dimensionsText,
            timesCompleted: record.timesCompleted,
            isDemo: record.isDemo,
            barcode: record.barcode,
            tags: record.tags,
            isOnLoan: false
        )
        puzzle.id = record.id
        if let imageData = record.imageData, let image = UIImage(data: imageData) {
            puzzle.image = image
        }
        puzzle.photos = photos
            .filter { $0.puzzleID == record.id }
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { photo in
                var mapped = PuzzlePhoto(sortOrder: photo.sortOrder)
                mapped.id = photo.id
                if let data = photo.imageData, let image = UIImage(data: data) {
                    mapped.image = image
                }
                return mapped
            }
        puzzle.completions = completions
            .filter { $0.puzzleID == record.id }
            .sorted { $0.completionNumber < $1.completionNumber }
            .map { row in
                PuzzleCompletion(
                    id: row.id,
                    completionNumber: row.completionNumber,
                    startedAt: row.startedAt,
                    completedAt: row.completedAt,
                    timeSpentHours: row.timeSpentHours,
                    timeSpentMinutes: row.timeSpentMinutes,
                    rating: row.rating
                )
            }
        return puzzle
    }

    private static func recreatePersistentContainer(url: URL) throws -> ModelContainer {
        try removeStoreFiles(at: url)
        UserPreferences.isRunningInEphemeralStore = false
        let container = try makeVersionedPersistent(url: url)
        UserPreferences.markStoreWasReset()
        AppLog.shared.error(
            .puzzles,
            eventName: "model_container_store_reset",
            message: "Saved collection was unreadable and was reset to a new empty store."
        )
        return container
    }

    private static func removeStoreFiles(at storeURL: URL) throws {
        let relatedURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + "-shm")
        ]
        for url in relatedURLs where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
