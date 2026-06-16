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
    @State private var searchText: String = ""
    @State private var statusFilter: PuzzleListStatusFilter = .all
    @State private var sortOption: PuzzleListSortOption = .completionDate
    @State private var missingPiecesOnly: Bool = false

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
                sortMenu
            }
        }
        .sheet(isPresented: $present) {
            PuzzleForm(isPresented: $present, ps: ps)
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                present.toggle()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 52))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Brand.textOnAccent, Brand.accent)
            }
            .accessibilityIdentifier(A11yID.addPuzzleButton)
            .accessibilityLabel("Add puzzle")
            .accessibilityHint("Opens the form to add a new puzzle")
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
        Text(emptyStateMessage)
            .font(.subheadline)
            .foregroundStyle(Brand.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.s6)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .accessibilityIdentifier(A11yID.puzzleListEmptyState)
            .accessibilityLabel(emptyStateMessage)
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
        let storeIndices = offsets.compactMap { offset -> Int? in
            let puzzleID = displayedPuzzles[offset].id
            return ps.puzzles.firstIndex(where: { $0.id == puzzleID })
        }
        ps.delete(at: IndexSet(storeIndices))
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
