//
//  PuzzleBrowseState.swift
//  Puzzle Buddy
//
//  Owned above the sidebar-adaptable tab so a size-class change can rebuild
//  the tab content without dropping the open puzzle, edit draft, or sheets.
//

import SwiftUI

@MainActor
final class PuzzleBrowseState: ObservableObject {
    @Published var selectedPuzzleID: UUID?
    @Published var editFormVm: PuzzleFormViewModel?
    @Published var showAddForm = false
    @Published var showScanner = false
    @Published var showShoppingMode = false
    @Published var showPickNext = false
    @Published var showFilterSheet = false
}
