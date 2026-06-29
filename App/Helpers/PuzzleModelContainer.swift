//
//  PuzzleModelContainer.swift
//  Puzzle Buddy
//

import Foundation
import SwiftData

enum PuzzleModelContainer {
    private static func makeInMemory(schema: Schema) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            UserPreferences.isRunningInEphemeralStore = true
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create in-memory ModelContainer: \(error)")
        }
    }

    static func makePersistent() -> ModelContainer {
        let schema = Schema([PuzzleRecord.self, PuzzlePhotoRecord.self, PuzzleCompletionRecord.self])

        if UITestSupport.isRunningUnderTest {
            return makeInMemory(schema: schema)
        }

        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            UserPreferences.isRunningInEphemeralStore = false
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            AppLog.shared.warning(
                .puzzles,
                eventName: "model_container_load_failed",
                message: error.localizedDescription
            )
            do {
                return try recreatePersistentContainer(schema: schema, configuration: configuration)
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
                return makeInMemory(schema: schema)
            }
        }
    }

    private static func recreatePersistentContainer(
        schema: Schema,
        configuration: ModelConfiguration
    ) throws -> ModelContainer {
        let storeURL = configuration.url
        let relatedURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + "-shm")
        ]

        for url in relatedURLs where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }

        UserPreferences.isRunningInEphemeralStore = false
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
