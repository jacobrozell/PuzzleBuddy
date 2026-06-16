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

    var body: some View {
        List {
            ForEach(ps.puzzles, id: \.id) { p in
                if let index = ps.puzzles.firstIndex(where: { $0.id == p.id }) {
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
            .onDelete(perform: { indexSet in
                ps.delete(at: indexSet)
            })
        }
        .accessibilityIdentifier(A11yID.puzzleList)
        .refreshable {
            await ps.fetchPuzzles()
        }
        .listStyle(.plain)
        .brandScreenChrome()
        .readableContentWidth()
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
            .padding(DS.Spacing.s4)
            .padding(.bottom, max(AdaptiveLayout.tabBarClearance(for: dynamicTypeSize) - 88, DS.Spacing.s2))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: verticalSizeClass == .compact ? DS.Spacing.s2 : 0)
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
