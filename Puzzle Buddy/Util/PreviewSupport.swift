//
//  PreviewSupport.swift
//  Puzzle Buddy
//

import SwiftData

enum PreviewSupport {
    @MainActor
    static var modelContext: ModelContext {
        previewContainer.mainContext
    }

    @MainActor
    static var puzzleStore: PuzzleStore {
        PuzzleStore(modelContext: modelContext)
    }

    @MainActor
    private static var previewContainer: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: PuzzleRecord.self, configurations: configuration)
    }()
}
