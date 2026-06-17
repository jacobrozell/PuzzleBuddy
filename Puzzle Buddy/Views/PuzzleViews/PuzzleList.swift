//
//  PuzzleList.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/23/22.
//

import SwiftUI


// MARK: - PuzzleList
struct PuzzleList: View {
    @EnvironmentObject var auth: FirebaseAuthProvider
    @EnvironmentObject var eh: ErrorHandling
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ObservedObject var ps: PuzzleStore
    @State private var present = false
    @State private var showScanner = false
    @State private var showShoppingMode = false
    @State private var openPuzzleRequest: OpenPuzzleRequest?
    @State private var quickAddContext: QuickAddContext?
    @State private var isLookingUpBarcode = false
    @State private var searchText: String = ""
    @State private var statusFilter: PuzzleListStatusFilter = .all
    @State private var sortOption: PuzzleListSortOption = .completionDate
    @State private var missingPiecesOnly: Bool = false
    @State private var pendingDeleteOffsets: IndexSet?

    private var displayedPuzzles: [Puzzle] {
        PuzzleListQuery.apply(
            puzzles: ps.puzzles,
            statusFilter: statusFilter,
            searchText: searchText,
            sortOption: sortOption,
            missingPiecesOnly: missingPiecesOnly
        )
    }

    private var hasActiveFilters: Bool {
        PuzzleListQuery.hasActiveFilters(
            statusFilter: statusFilter,
            searchText: searchText,
            missingPiecesOnly: missingPiecesOnly
        )
    }

    private var hasActiveSearch: Bool {
        PuzzleListQuery.hasActiveSearch(searchText)
    }

    var body: some View {
        List {
            if displayedPuzzles.isEmpty {
                emptyStateRow
            } else {
                ForEach(displayedPuzzles, id: \.id) { puzzle in
                    if let index = ps.puzzles.firstIndex(where: { $0.id == puzzle.id }) {
                        PuzzleCell(ps: ps, puzzle: $ps.puzzles[index])
                            .id(ps.puzzles[index].id)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(
                                top: DS.Spacing.s2,
                                leading: DS.Spacing.s4,
                                bottom: DS.Spacing.s2,
                                trailing: DS.Spacing.s4
                            ))
                    }
                }
                .onDelete(perform: deleteDisplayedPuzzles)
            }
        }
        .accessibilityIdentifier(A11yID.puzzleList)
        .refreshable {
            await ps.fetchPuzzles()
        }
        .listStyle(.plain)
        .readableBrandScreenChrome()
        .safeAreaInset(edge: .top, spacing: 0) {
            statusFilterPicker
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: DS.Spacing.s3) {
                    if ProductService.isShoppingModeEnabled {
                        Button {
                            showShoppingMode = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                        }
                        .accessibilityLabel("Check duplicate")
                        .accessibilityHint("Scan a barcode to see if you already own this puzzle")
                        .optionalAccessibilityIdentifier(A11yID.checkDuplicateButton)
                        .disabled(!ProductService.isBarcodeScanEnabled && !AppInfo.isUITesting)
                    }
                    PuzzleShareMenu(
                        entireCollection: ps.puzzles,
                        visibleList: displayedPuzzles
                    )
                    sortMenu
                }
            }
        }
        .sheet(isPresented: $present) {
            PuzzleForm(isPresented: $present, ps: ps)
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerSheet { barcode in
                handleScannedBarcode(barcode)
            }
        }
        .sheet(item: $quickAddContext) { context in
            QuickAddPuzzleSheet(
                ps: ps,
                barcode: context.barcode,
                metadata: context.metadata
            )
        }
        .sheet(isPresented: $showShoppingMode) {
            ShoppingModeView(
                ps: ps,
                onAddPuzzle: { barcode in
                    beginQuickAdd(barcode: barcode, skipLookup: true)
                },
                onOpenPuzzle: { puzzle in
                    openPuzzleRequest = OpenPuzzleRequest(id: puzzle.id)
                }
            )
        }
        .navigationDestination(item: $openPuzzleRequest) { request in
            if let index = ps.puzzles.firstIndex(where: { $0.id == request.id }) {
                PuzzleDetail(ps: ps, puzzle: $ps.puzzles[index])
            }
        }
        .overlay {
            if isLookingUpBarcode {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    ProgressView("Looking up product…")
                        .padding()
                        .background(Brand.card)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Looking up product information for barcode")
            }
        }
        .confirmationDialog(
            "Delete puzzle?",
            isPresented: Binding(
                get: { pendingDeleteOffsets != nil },
                set: { if !$0 { pendingDeleteOffsets = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let offsets = pendingDeleteOffsets {
                    performDelete(at: offsets)
                }
                pendingDeleteOffsets = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteOffsets = nil
            }
        } message: {
            Text("This puzzle will be removed from your collection. This cannot be undone.")
        }
        .overlay(alignment: .bottomTrailing) {
            Menu {
                Button {
                    present = true
                } label: {
                    Label("Add puzzle", systemImage: "plus")
                }
                .accessibilityIdentifier(A11yID.addPuzzleButton)

                Button {
                    showScanner = true
                } label: {
                    Label("Scan barcode", systemImage: "barcode.viewfinder")
                }
                .optionalAccessibilityIdentifier(A11yID.scanBarcodeButton)
                .disabled(!ProductService.isBarcodeScanEnabled && !AppInfo.isUITesting)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 52))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Brand.textOnAccent, Brand.accent)
            }
            .accessibilityLabel("Add puzzle")
            .accessibilityHint("Opens menu to add a puzzle or scan a barcode")
            .padding(DS.Spacing.s4)
            .padding(.bottom, max(AdaptiveLayout.tabBarClearance(for: dynamicTypeSize) - 88, DS.Spacing.s2))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: verticalSizeClass == .compact ? DS.Spacing.s2 : 0)
        }
    }

    private var statusFilterPicker: some View {
        VStack(spacing: DS.Spacing.s2) {
            Picker("Filter puzzles by status", selection: $statusFilter) {
                ForEach(PuzzleListStatusFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Filter puzzles by status")
            .accessibilityValue(statusFilter.title)

            HStack(spacing: DS.Spacing.s2) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityHidden(true)

                TextField("Search by name", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier(A11yID.puzzleListSearchField)
                    .accessibilityLabel("Search by name")
                    .accessibilityHint("Filters the puzzle list as you type")

                if hasActiveSearch {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Brand.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                    .accessibilityHint("Clears the search field")
                }
            }
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s2)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))

            if !ps.puzzles.isEmpty {
                HStack {
                    Text(PuzzleListQuery.resultCountLabel(
                        displayedCount: displayedPuzzles.count,
                        totalCount: ps.puzzles.count,
                        hasActiveFilters: hasActiveFilters
                    ))
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityIdentifier(A11yID.puzzleListResultCount)

                    Spacer()

                    missingPiecesFilterToggle
                }
            }
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.vertical, DS.Spacing.s2)
        .background(Brand.background.opacity(0.95))
        .accessibilityIdentifier(A11yID.puzzleListStatusFilter)
        .accessibilityElement(children: .contain)
    }

    private var missingPiecesFilterToggle: some View {
        Button {
            missingPiecesOnly.toggle()
        } label: {
            Label("Missing pieces", systemImage: missingPiecesOnly ? "checkmark.circle.fill" : "circle")
                .font(.caption.weight(.medium))
                .foregroundStyle(missingPiecesOnly ? Brand.accentWarm : Brand.textSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11yID.puzzleListMissingPiecesFilter)
        .accessibilityLabel("Filter missing pieces")
        .accessibilityValue(missingPiecesOnly ? "On" : "Off")
        .accessibilityHint("Shows only puzzles flagged with missing pieces")
    }

    private var sortMenu: some View {
        Menu {
            ForEach(PuzzleListSortOption.allCases) { option in
                Button {
                    sortOption = option
                } label: {
                    if sortOption == option {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
                .accessibilityLabel(option.accessibilityLabel)
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
        }
        .accessibilityIdentifier(A11yID.puzzleListSortMenu)
        .accessibilityLabel("Sort puzzles, \(sortOption.title)")
    }

    private var emptyStateRow: some View {
        VStack(spacing: DS.Spacing.s3) {
            Image(systemName: "puzzlepiece.extension")
                .font(.system(size: 40))
                .foregroundStyle(Brand.accent)
                .accessibilityHidden(true)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)

            if showsAddPuzzleAction {
                Button("Add puzzle") {
                    present = true
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .accessibilityHint("Opens the form to add a new puzzle")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.s6)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .accessibilityIdentifier(A11yID.puzzleListEmptyState)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(emptyStateAccessibilityLabel)
    }

    private var showsAddPuzzleAction: Bool {
        ps.puzzles.isEmpty && !hasActiveFilters
    }

    private var emptyStateAccessibilityLabel: String {
        if showsAddPuzzleAction {
            return "\(emptyStateMessage) Add puzzle button available."
        }
        return emptyStateMessage
    }

    private var emptyStateMessage: String {
        if missingPiecesOnly {
            return hasActiveSearch
                ? "No puzzles with missing pieces match your search."
                : "No puzzles flagged with missing pieces."
        }
        return statusFilter.emptyStateMessage(hasSearchQuery: hasActiveSearch)
    }

    private func deleteDisplayedPuzzles(at offsets: IndexSet) {
        pendingDeleteOffsets = offsets
    }

    private func performDelete(at offsets: IndexSet) {
        let storeIndices = offsets.compactMap { offset -> Int? in
            let puzzleID = displayedPuzzles[offset].id
            return ps.puzzles.firstIndex(where: { $0.id == puzzleID })
        }
        ps.delete(at: IndexSet(storeIndices))
    }

    private func handleScannedBarcode(_ raw: String) {
        if let duplicate = ps.findPuzzle(matchingBarcode: raw) {
            eh.handle(
                title: "Already in your collection",
                message: "\(duplicate.name) already uses this barcode."
            )
            return
        }

        beginQuickAdd(barcode: raw, skipLookup: false)
    }

    private func beginQuickAdd(barcode raw: String, skipLookup: Bool) {
        guard let normalized = BarcodeNormalizer.normalize(raw) ?? optionalDigits(from: raw) else {
            eh.handle(
                title: "Invalid barcode",
                message: "Enter a barcode with 6 to 14 digits, or try scanning again."
            )
            return
        }

        if let local = BarcodeMetadataCache.metadata(for: normalized) {
            quickAddContext = QuickAddContext(barcode: normalized, metadata: local)
            return
        }

        guard !skipLookup, ProductService.isBarcodeLookupEnabled else {
            quickAddContext = QuickAddContext(barcode: normalized, metadata: nil)
            return
        }

        isLookingUpBarcode = true
        Task {
            let metadata = await BarcodeLookupService.lookup(barcode: normalized)
            await MainActor.run {
                isLookingUpBarcode = false
                quickAddContext = QuickAddContext(barcode: normalized, metadata: metadata)
            }
        }
    }

    private func optionalDigits(from raw: String) -> String? {
        let digits = raw.filter(\.isNumber)
        return digits.isEmpty ? nil : digits
    }
}

private struct QuickAddContext: Identifiable {
    let id = UUID()
    let barcode: String
    let metadata: BarcodeProductMetadata?
}

private struct OpenPuzzleRequest: Identifiable, Hashable {
    let id: UUID
}

// MARK: - Previews
struct PuzzleListPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            let ps = PreviewSupport.puzzleStore
            PuzzleList(ps: ps)
                .task {
                    ps.puzzles.append(.fixture())
                    ps.puzzles.append(.fixture())
                }
        }
    }
}
