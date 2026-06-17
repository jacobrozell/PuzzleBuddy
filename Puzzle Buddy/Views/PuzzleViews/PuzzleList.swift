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
    @State private var showPickNext = false
    @State private var openPuzzleRequest: OpenPuzzleRequest?
    @State private var quickAddContext: QuickAddContext?
    @State private var isLookingUpBarcode = false
    @State private var searchText: String = ""
    @State private var statusFilter: PuzzleListStatusFilter = .all
    @State private var sortOption: PuzzleListSortOption = .completionDate
    @State private var missingPiecesOnly: Bool = false
    @State private var needsPhotoOnly: Bool = false
    @State private var pieceCountFilter: PuzzleListPieceCountFilter = .any
    @State private var tagFilter: String? = nil
    @State private var pendingDeleteOffsets: IndexSet?

    private var displayedPuzzles: [Puzzle] {
        PuzzleListQuery.apply(
            puzzles: ps.puzzles,
            statusFilter: statusFilter,
            searchText: searchText,
            sortOption: sortOption,
            missingPiecesOnly: missingPiecesOnly,
            needsPhotoOnly: needsPhotoOnly,
            pieceCountFilter: pieceCountFilter,
            tagFilter: tagFilter
        )
    }

    private var availableTags: [PuzzleTagCount] {
        PuzzleTagIndex.counts(from: ps.puzzles)
    }

    private var hasActiveFilters: Bool {
        PuzzleListQuery.hasActiveFilters(
            statusFilter: statusFilter,
            searchText: searchText,
            missingPiecesOnly: missingPiecesOnly,
            needsPhotoOnly: needsPhotoOnly,
            pieceCountFilter: pieceCountFilter,
            tagFilter: tagFilter
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
                    if ProductService.isPickNextEnabled {
                        Button {
                            showPickNext = true
                        } label: {
                            Image(systemName: "dice")
                        }
                        .accessibilityLabel("Pick my next puzzle")
                        .accessibilityHint("Opens a random picker from your To-Do backlog")
                        .accessibilityIdentifier(A11yID.pickNextButton)
                    }
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
                metadata: context.metadata,
                lookupNotice: context.lookupNotice
            )
        }
        .sheet(isPresented: $showPickNext) {
            PickNextPuzzleView(ps: ps)
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
        .onChange(of: statusFilter) { _, newValue in
            sortOption = PuzzleListSortOption.defaultFor(statusFilter: newValue)
        }
        .overlay {
            if isLookingUpBarcode {
                ZStack {
                    Color.black.opacity(0.25).ignoresSafeArea()
                    VStack(spacing: DS.Spacing.s3) {
                        ProgressView()
                        Text("Looking up product…")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.textPrimary)
                    }
                    .padding(DS.Spacing.s5)
                    .background(Brand.card)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Looking up product details for this barcode")
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

                TextField("Search name, brand, tag, or barcode", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier(A11yID.puzzleListSearchField)
                    .accessibilityLabel("Search name, brand, tag, or barcode")
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
                if verticalSizeClass == .compact {
                    VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                        Text(PuzzleListQuery.resultCountLabel(
                            displayedCount: displayedPuzzles.count,
                            totalCount: ps.puzzles.count,
                            hasActiveFilters: hasActiveFilters
                        ))
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                        .accessibilityIdentifier(A11yID.puzzleListResultCount)

                        listFilterControls
                    }
                } else {
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

                        listFilterControls
                    }
                }
            }
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.vertical, DS.Spacing.s2)
        .background(Brand.background.opacity(0.95))
        .accessibilityIdentifier(A11yID.puzzleListStatusFilter)
        .accessibilityElement(children: .contain)
    }

    private var listFilterControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: DS.Spacing.s2) {
                pieceCountFilterMenu
                tagFilterMenu
                needsPhotoFilterToggle
                missingPiecesFilterToggle
            }

            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                pieceCountFilterMenu
                tagFilterMenu
                HStack(spacing: DS.Spacing.s2) {
                    needsPhotoFilterToggle
                    missingPiecesFilterToggle
                }
            }
        }
    }

    private var pieceCountFilterMenu: some View {
        Menu {
            ForEach(PuzzleListPieceCountFilter.allCases) { filter in
                Button {
                    pieceCountFilter = filter
                } label: {
                    if pieceCountFilter == filter {
                        Label(filter.title, systemImage: "checkmark")
                    } else {
                        Text(filter.title)
                    }
                }
                .accessibilityLabel(filter.accessibilityLabel)
            }
        } label: {
            Label(pieceCountFilter.title, systemImage: "number")
                .font(.caption.weight(.medium))
                .foregroundStyle(pieceCountFilter == .any ? Brand.textSecondary : Brand.accent)
        }
        .accessibilityIdentifier(A11yID.puzzleListPieceCountFilter)
        .accessibilityLabel("Filter by piece count, \(pieceCountFilter.title)")
    }

    private var tagFilterMenu: some View {
        Menu {
            Button {
                tagFilter = nil
            } label: {
                if tagFilter == nil {
                    Label("Any tag", systemImage: "checkmark")
                } else {
                    Text("Any tag")
                }
            }

            ForEach(availableTags) { tag in
                Button {
                    tagFilter = tag.name
                } label: {
                    if tagFilter?.caseInsensitiveCompare(tag.name) == .orderedSame {
                        Label("\(tag.name) (\(tag.count))", systemImage: "checkmark")
                    } else {
                        Text("\(tag.name) (\(tag.count))")
                    }
                }
                .accessibilityLabel("Filter by tag \(tag.name), \(tag.count) puzzles")
            }
        } label: {
            Label(tagFilter ?? "Tags", systemImage: "tag")
                .font(.caption.weight(.medium))
                .foregroundStyle(tagFilter == nil ? Brand.textSecondary : Brand.accent)
        }
        .accessibilityIdentifier(A11yID.puzzleListTagFilter)
        .accessibilityLabel("Filter by tag, \(tagFilter ?? "any")")
        .disabled(availableTags.isEmpty)
    }

    private var needsPhotoFilterToggle: some View {
        Button {
            needsPhotoOnly.toggle()
        } label: {
            Label("Needs photo", systemImage: needsPhotoOnly ? "photo.badge.checkmark.fill" : "photo")
                .font(.caption.weight(.medium))
                .foregroundStyle(needsPhotoOnly ? Brand.accentWarm : Brand.textSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11yID.puzzleListNeedsPhotoFilter)
        .accessibilityLabel("Filter needs photo")
        .accessibilityValue(needsPhotoOnly ? "On" : "Off")
        .accessibilityHint("Shows only puzzles without a box photo")
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
        if needsPhotoOnly {
            return hasActiveSearch
                ? "No puzzles without photos match your search."
                : "Every puzzle in this view has a photo."
        }
        if missingPiecesOnly {
            return hasActiveSearch
                ? "No puzzles with missing pieces match your search."
                : "No puzzles flagged with missing pieces."
        }
        if pieceCountFilter != .any {
            return hasActiveSearch
                ? "No puzzles in this piece-count range match your search."
                : "No puzzles match this piece-count filter."
        }
        if tagFilter != nil {
            return statusFilter.emptyStateMessage(hasSearchQuery: hasActiveSearch, hasTagFilter: true)
        }
        return statusFilter.emptyStateMessage(hasSearchQuery: hasActiveSearch, hasTagFilter: false)
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
            quickAddContext = QuickAddContext(barcode: normalized, metadata: local, lookupNotice: nil)
            return
        }

        guard !skipLookup, ProductService.isBarcodeLookupEnabled else {
            quickAddContext = QuickAddContext(barcode: normalized, metadata: nil, lookupNotice: nil)
            return
        }

        isLookingUpBarcode = true
        Task {
            let result = await BarcodeLookupService.lookup(barcode: normalized)
            await MainActor.run {
                isLookingUpBarcode = false
                quickAddContext = QuickAddContext(
                    barcode: normalized,
                    metadata: result.metadata,
                    lookupNotice: result.notice?.message
                )
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
    let lookupNotice: String?
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
