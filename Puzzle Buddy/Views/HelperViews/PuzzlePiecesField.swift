//
//  PuzzlePiecesField.swift
//  Puzzle Buddy
//

import SwiftUI

private enum PiecesSelection: Hashable {
    case common(Int)
    case custom
}

struct PuzzlePiecesField: View {
    @Binding var pieces: Int?

    @State private var selection: PiecesSelection = .custom
    @State private var customPieces = ""

    var body: some View {
        Group {
            Picker("Pieces", selection: $selection) {
                ForEach(PuzzlePieceCount.commonValues, id: \.self) { count in
                    Text(PuzzlePieceCount.formatted(count)).tag(PiecesSelection.common(count))
                }
                Text("Custom").tag(PiecesSelection.custom)
            }
            .accessibilityLabel("Number of pieces")

            if case .custom = selection {
                TextField("Custom pieces", text: $customPieces)
                    .keyboardType(.numberPad)
                    .optionalAccessibilityIdentifier(A11yID.puzzleFormPiecesField)
                    .accessibilityLabel("Custom number of pieces")
                    .onChange(of: customPieces) { _, newValue in
                        let digits = newValue.filter(\.isNumber)
                        if digits != newValue {
                            customPieces = digits
                        }
                        pieces = Int(digits)
                    }
            }
        }
        .onAppear {
            syncSelectionFromPieces()
        }
        .onChange(of: selection) { _, newValue in
            switch newValue {
            case .common(let count):
                pieces = count
            case .custom:
                if let pieces, !PuzzlePieceCount.matchesCommon(pieces) {
                    customPieces = "\(pieces)"
                } else {
                    pieces = nil
                    customPieces = ""
                }
            }
        }
    }

    private func syncSelectionFromPieces() {
        if let pieces, let match = PuzzlePieceCount.commonValues.first(where: { $0 == pieces }) {
            selection = .common(match)
        } else {
            selection = .custom
            customPieces = pieces.map(String.init) ?? ""
        }
    }
}
