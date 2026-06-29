//
//  PuzzleList.swift
//  Puzzle Buddy
//
//  Created by Jacob Rozell on 7/23/22.
//

import SwiftUI


// MARK: - PuzzleList
struct PuzzleList: View {
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
    @State private var listScanDuplicate: ListScanDuplicateRequest?
    @State private var searchText: String = ""
    @State private var statusFilter: PuzzleListStatusFilter = .all
    @State private var sortOption: PuzzleListSortOption = .completionDate
    @State private var missingPiecesOnly: Bool = false
    @State private var needsPhotoOnly: Bool = false
    @State private var pieceCountFilter: PuzzleListPieceCountFilter = .any
    @State private var tagFilter: String? = nil
    @State private var typeFilter: PuzzleType? = nil
    @State private var materialFilter: PuzzleMaterial? = nil
    @State private var dispositionFilter: PuzzleDisposition? = nil
    @State private var showTagFilterSheet = false
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
            tagFilter: tagFilter,
            typeFilter: typeFilter,
            materialFilter: materialFilter,
            dispositionFilter: dispositionFilter
        )
    }

    private var availableTags: [PuzzleTagCount] {
        PuzzleTagIndex.counts(from: ps.puzzles, limit: Int.max)
    }

    private var hasActiveFilters: Bool {
        PuzzleListQuery.hasActiveFilters(
            statusFilter: statusFilter,
            searchText: searchText,
            missingPiecesOnly: missingPiecesOnly,
            needsPhotoOnly: needsPhotoOnly,
            pieceCountFilter: pieceCountFilter,
            tagFilter: tagFilter,
            typeFilter: typeFilter,
            materialFilter: materialFilter,
            dispositionFilter: dispositionFilter
        )
    }

    private var hasActiveSearch: Bool {
        PuzzleListQuery.hasActiveSearch(searchText)
    }

    private var hasSecondaryFilters: Bool {
        PuzzleListQuery.hasSecondaryFilters(
            searchText: searchText,
            missingPiecesOnly: missingPiecesOnly,
            needsPhotoOnly: needsPhotoOnly,
            pieceCountFilter: pieceCountFilter,
            tagFilter: tagFilter,
            typeFilter: typeFilter,
            materialFilter: materialFilter,
            dispositionFilter: dispositionFilter
        )
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
        .overlay {
            if ps.state == .fetching, ps.puzzles.isEmpty {
                ProgressView("Loading puzzles…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Brand.background.opacity(0.92))
            }
        }
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
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
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
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Check duplicate")
                        .accessibilityHint("Scan a barcode to see if you already own this puzzle while shopping")
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
        .sheet(item: $listScanDuplicate) { request in
            NavigationStack {
                ScrollView {
                    BarcodeScanResultCard(
                        result: .match(request.puzzle),
                        onOpenPuzzle: { puzzle in
                            listScanDuplicate = nil
                            openPuzzleRequest = OpenPuzzleRequest(id: puzzle.id)
                        },
                        onAddPuzzle: { _ in },
                        onScanAnother: {
                            listScanDuplicate = nil
                            showScanner = true
                        }
                    )
                    .padding(DS.Spacing.s4)
                }
                .readableBrandScreenChrome()
                .navigationTitle("Already in collection")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            listScanDuplicate = nil
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showPickNext) {
            PickNextPuzzleView(ps: ps, entryPoint: "list")
        }
        .sheet(isPresented: $showShoppingMode) {
            ShoppingModeView(
                ps: ps,
                onAddPuzzle: { barcode in
                    beginQuickAdd(barcode: barcode)
                },
                onOpenPuzzle: { puzzle in
                    openPuzzleRequest = OpenPuzzleRequest(id: puzzle.id)
                }
            )
        }
        .navigationDestination(item: $openPuzzleRequest) { request in
            if let index = ps.puzzles.firstIndex(where: { $0.id == request.id }) {
                PuzzleDetail(ps: ps, puzzle: $ps.puzzles[index])
            } else {
                MissingPuzzleDestination()
            }
        }
        .sheet(isPresented: $showTagFilterSheet) {
            TagFilterSheet(
                tags: availableTags,
                selection: $tagFilter
            )
        }
        .onChange(of: statusFilter) { _, newValue in
            sortOption = PuzzleListSortOption.defaultFor(statusFilter: newValue)
        }
        .onChange(of: ps.puzzles.count) { _, _ in
            applyMarketingSnapshotNavigation()
        }
        .onAppear {
            applyMarketingSnapshotNavigation()
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
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scan barcode")
                            Text("Add to your collection")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "barcode.viewfinder")
                    }
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

                TextField("Search name, brand, store, tag, or barcode", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .accessibilityIdentifier(A11yID.puzzleListSearchField)
                    .accessibilityLabel("Search name, brand, store, tag, or barcode")
                    .accessibilityHint("Filters the puzzle list as you type")

                if hasActiveSearch {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Brand.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Clear search")
                    .accessibilityHint("Clears the search field")
                }
            }
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s2)
            .background(Brand.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))

            if !ps.puzzles.isEmpty {
                HStack(alignment: .center, spacing: DS.Spacing.s2) {
                    Text(PuzzleListQuery.resultCountLabel(
                        displayedCount: displayedPuzzles.count,
                        totalCount: ps.puzzles.count,
                        hasActiveFilters: hasActiveFilters
                    ))
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityIdentifier(A11yID.puzzleListResultCount)

                    if hasSecondaryFilters {
                        Button("Clear filters") {
                            clearSecondaryFilters()
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.accent)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier(A11yID.puzzleListClearFilters)
                        .accessibilityHint("Clears search, tag, and other list filters")
                    }

                    Spacer(minLength: 0)

                    if verticalSizeClass != .compact {
                        listFilterControls
                    }
                }

                if verticalSizeClass == .compact {
                    listFilterControls
                }
            }
        }
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.vertical, DS.Spacing.s2)
        .background {
            Brand.background.opacity(0.95)
                .overlay(alignment: .bottom) {
                    Divider()
                }
        }
        .accessibilityIdentifier(A11yID.puzzleListStatusFilter)
        .accessibilityElement(children: .contain)
    }

    private var listFilterControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Spacing.s2) {
                pieceCountFilterMenu
                typeFilterMenu
                materialFilterMenu
                dispositionFilterMenu
                tagFilterButton
                needsPhotoFilterToggle
                missingPiecesFilterToggle
            }
        }
    }

    private func clearSecondaryFilters() {
        searchText = ""
        missingPiecesOnly = false
        needsPhotoOnly = false
        pieceCountFilter = .any
        tagFilter = nil
        typeFilter = nil
        materialFilter = nil
        dispositionFilter = nil
    }

    private var typeFilterMenu: some View {
        Menu {
            Button { typeFilter = nil } label: {
                if typeFilter == nil { Label("Any type", systemImage: "checkmark") } else { Text("Any type") }
            }
            ForEach(PuzzleType.selectableCases) { type in
                Button { typeFilter = type } label: {
                    if typeFilter == type { Label(type.displayLabel, systemImage: "checkmark") }
                    else { Text(type.displayLabel) }
                }
            }
        } label: {
            listFilterChipLabel(
                typeFilter?.displayLabel ?? "Type",
                systemImage: "square.grid.2x2",
                isActive: typeFilter != nil
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11yID.puzzleListTypeFilter)
    }

    private var materialFilterMenu: some View {
        Menu {
            Button { materialFilter = nil } label: {
                if materialFilter == nil { Label("Any material", systemImage: "checkmark") } else { Text("Any material") }
            }
            ForEach(PuzzleMaterial.selectableCases) { material in
                Button { materialFilter = material } label: {
                    if materialFilter == material { Label(material.displayLabel, systemImage: "checkmark") }
                    else { Text(material.displayLabel) }
                }
            }
        } label: {
            listFilterChipLabel(
                materialFilter?.displayLabel ?? "Material",
                systemImage: "square.stack.3d.up",
                isActive: materialFilter != nil
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11yID.puzzleListMaterialFilter)
    }

    private var dispositionFilterMenu: some View {
        Menu {
            Button { dispositionFilter = nil } label: {
                if dispositionFilter == nil { Label("Any disposition", systemImage: "checkmark") } else { Text("Any disposition") }
            }
            ForEach(PuzzleDisposition.selectableCases) { disposition in
                Button { dispositionFilter = disposition } label: {
                    if dispositionFilter == disposition { Label(disposition.displayLabel, systemImage: "checkmark") }
                    else { Text(disposition.displayLabel) }
                }
            }
        } label: {
            listFilterChipLabel(
                dispositionFilter?.displayLabel ?? "Fate",
                systemImage: "arrow.triangle.branch",
                isActive: dispositionFilter != nil
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11yID.puzzleListDispositionFilter)
    }

    private func listFilterChipLabel(
        _ title: String,
        systemImage: String,
        isActive: Bool,
        activeColor: Color = Brand.accent
    ) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isActive ? activeColor : Brand.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(isActive ? activeColor.opacity(0.14) : Brand.card)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        isActive ? activeColor.opacity(0.45) : Brand.textSecondary.opacity(0.22),
                        lineWidth: 1
                    )
            }
            .contentShape(Capsule())
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
            listFilterChipLabel(
                pieceCountFilter.title,
                systemImage: "number",
                isActive: pieceCountFilter != .any
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11yID.puzzleListPieceCountFilter)
        .accessibilityLabel("Filter by piece count, \(pieceCountFilter.title)")
    }

    private var tagFilterButton: some View {
        Button {
            showTagFilterSheet = true
        } label: {
            listFilterChipLabel(
                tagFilter ?? "Tags",
                systemImage: "tag",
                isActive: tagFilter != nil
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11yID.puzzleListTagFilter)
        .accessibilityLabel("Filter by tag, \(tagFilter ?? "any")")
        .accessibilityHint("Opens a searchable list of tags")
        .disabled(availableTags.isEmpty)
    }

    private var needsPhotoFilterToggle: some View {
        Button {
            needsPhotoOnly.toggle()
        } label: {
            listFilterChipLabel(
                "Needs photo",
                systemImage: needsPhotoOnly ? "photo.badge.checkmark.fill" : "photo",
                isActive: needsPhotoOnly,
                activeColor: Brand.accentWarm
            )
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
            listFilterChipLabel(
                "Missing pieces",
                systemImage: missingPiecesOnly ? "checkmark.circle.fill" : "circle",
                isActive: missingPiecesOnly,
                activeColor: Brand.accentWarm
            )
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
                .font(.title3)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
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
        do {
            try ps.delete(at: IndexSet(storeIndices))
            BarcodeScanFeedback.scanAccepted()
        } catch {
            eh.handle(title: "Could not delete puzzle", message: error.localizedDescription)
        }
    }

    private func applyMarketingSnapshotNavigation() {
        guard MarketingSnapshotBootstrap.isMarketingCapture else { return }

        if MarketingSnapshotBootstrap.shouldShowAddPuzzle {
            present = true
        }

        guard !ps.puzzles.isEmpty else { return }

        if let id = MarketingSnapshotBootstrap.puzzleDetailID(in: ps.puzzles) {
            openPuzzleRequest = OpenPuzzleRequest(id: id)
        }

        if let puzzle = MarketingSnapshotBootstrap.duplicateCheckPuzzle(in: ps.puzzles) {
            listScanDuplicate = ListScanDuplicateRequest(puzzle: puzzle)
        }
    }

    private func handleScannedBarcode(_ raw: String) {
        guard let normalized = BarcodeNormalizer.normalize(raw) ?? BarcodeNormalizer.optionalDigits(from: raw) else {
            eh.handle(
                title: "Invalid barcode",
                message: "Enter a barcode with 6 to 14 digits, or try scanning again."
            )
            return
        }

        if let duplicate = ps.findPuzzle(matchingBarcode: normalized) {
            BarcodeScanFeedback.duplicateFound()
            listScanDuplicate = ListScanDuplicateRequest(puzzle: duplicate)
            AppLog.shared.info(
                .puzzles,
                eventName: "barcode_scan_completed",
                message: "Barcode scan completed.",
                metadata: ["scan_context": "list_scan", "scan_result": "match"]
            )
            return
        }

        BarcodeScanFeedback.scanAccepted()
        AppLog.shared.info(
            .puzzles,
            eventName: "barcode_scan_completed",
            message: "Barcode scan completed.",
            metadata: ["scan_context": "list_scan", "scan_result": "no_match"]
        )
        beginQuickAdd(barcode: normalized)
    }

    private func beginQuickAdd(barcode normalized: String) {
        let metadata = BarcodeMetadataCache.metadata(for: normalized)
        quickAddContext = QuickAddContext(barcode: normalized, metadata: metadata)
    }
}

private struct QuickAddContext: Identifiable {
    let id = UUID()
    let barcode: String
    let metadata: BarcodeProductMetadata?
}

private struct ListScanDuplicateRequest: Identifiable {
    let id: UUID
    let puzzle: Puzzle

    init(puzzle: Puzzle) {
        id = puzzle.id
        self.puzzle = puzzle
    }
}

private struct OpenPuzzleRequest: Identifiable, Hashable {
    let id: UUID
}

private struct TagFilterSheet: View {
    let tags: [PuzzleTagCount]
    @Binding var selection: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredTags: [PuzzleTagCount] {
        PuzzleTagIndex.filteredCounts(tags, matching: searchText)
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selection = nil
                        dismiss()
                    } label: {
                        tagRow(
                            name: "Any tag",
                            badge: "All",
                            isSelected: selection == nil
                        )
                    }
                    .accessibilityLabel("Any tag")
                    .accessibilityAddTraits(selection == nil ? .isSelected : [])
                }

                Section {
                    if filteredTags.isEmpty {
                        ContentUnavailableView(
                            "No matching tags",
                            systemImage: "tag.slash",
                            description: Text(
                                trimmedSearch.isEmpty
                                    ? "Add tags to puzzles to filter by them here."
                                    : "Try a different spelling or clear your search."
                            )
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredTags) { tag in
                            Button {
                                selection = tag.name
                                dismiss()
                            } label: {
                                tagRow(
                                    name: tag.name,
                                    badge: "\(tag.count)",
                                    isSelected: selection?.caseInsensitiveCompare(tag.name) == .orderedSame
                                )
                            }
                            .accessibilityLabel("Filter by tag \(tag.name), \(tag.count) puzzles")
                            .accessibilityAddTraits(
                                selection?.caseInsensitiveCompare(tag.name) == .orderedSame ? .isSelected : []
                            )
                        }
                    }
                } header: {
                    if trimmedSearch.isEmpty {
                        Text("Your tags")
                    } else {
                        Text("Results")
                    }
                } footer: {
                    if !trimmedSearch.isEmpty, !filteredTags.isEmpty {
                        Text("\(filteredTags.count) tag\(filteredTags.count == 1 ? "" : "s") match “\(trimmedSearch)”.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search tags")
            .navigationTitle("Filter by tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func tagRow(
        name: String,
        badge: String,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: DS.Spacing.s3) {
            Image(systemName: "tag.fill")
                .foregroundStyle(isSelected ? Brand.accent : Brand.textSecondary)
                .accessibilityHidden(true)

            Text(name)
                .foregroundStyle(Brand.textPrimary)

            Spacer()

            Text(badge)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Brand.textOnAccent : Brand.textSecondary)
                .padding(.horizontal, DS.Spacing.s2)
                .padding(.vertical, 4)
                .background(isSelected ? Brand.accent : Brand.cardElevated)
                .clipShape(Capsule())

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(Brand.accent)
                    .accessibilityHidden(true)
            }
        }
    }
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
