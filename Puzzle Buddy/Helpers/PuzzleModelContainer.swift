//
//  PuzzleModelContainer.swift
//  Puzzle Buddy
//

import Foundation
import SwiftData

enum PuzzleModelContainer {
    static func makePersistent() -> ModelContainer {
        let schema = Schema([PuzzleRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            AppLog.shared.warning(
                .puzzles,
                eventName: "model_container_load_failed",
                message: error.localizedDescription
            )

            if UITestSupport.isRunningUnderTest {
                return recreatePersistentContainer(schema: schema, configuration: configuration, after: error)
            }

            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private static func recreatePersistentContainer(
        schema: Schema,
        configuration: ModelConfiguration,
        after error: Error
    ) -> ModelContainer {
        let storeURL = configuration.url
        let relatedURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + "-shm")
        ]

        for url in relatedURLs where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch let recreationError {
            fatalError("Could not recreate ModelContainer after reset: \(recreationError). Original: \(error)")
        }
    }
}
