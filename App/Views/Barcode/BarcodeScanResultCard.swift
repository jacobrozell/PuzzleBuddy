//
//  BarcodeScanResultCard.swift
//  Puzzle Buddy
//

import SwiftUI

enum BarcodeScanResult {
    case match(Puzzle)
    case noMatch(barcode: String)
}

struct BarcodeScanResultCard: View {
    let result: BarcodeScanResult
    let onOpenPuzzle: (Puzzle) -> Void
    let onAddPuzzle: (String) -> Void
    let onScanAnother: () -> Void
    var showsScanAnother: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            header
            content
            actions
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    @ViewBuilder
    private var header: some View {
        switch result {
        case .match:
            Label("You already own this", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(Brand.accent)
        case .noMatch:
            Label("Not in your collection", systemImage: "bag.badge.plus")
                .font(.headline)
                .foregroundStyle(Brand.accentWarm)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch result {
        case .match(let puzzle):
            HStack(alignment: .top, spacing: DS.Spacing.s3) {
                puzzleThumbnail(for: puzzle)
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text(puzzle.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Brand.textPrimary)
                        .multilineTextAlignment(.leading)
                    if let pieces = puzzle.pieces {
                        Text("\(pieces) pieces")
                            .font(.subheadline)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    PuzzleStatusPill(status: puzzle.status)
                }
            }
        case .noMatch(let barcode):
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                Text("No puzzle in your collection uses this barcode.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                Text(barcode)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Brand.textPrimary)
                    .padding(.horizontal, DS.Spacing.s2)
                    .padding(.vertical, DS.Spacing.s2)
                    .background(Brand.cardElevated)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm, style: .continuous))
            }
            .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch result {
        case .match(let puzzle):
            VStack(spacing: DS.Spacing.s2) {
                Button("Open puzzle") {
                    onOpenPuzzle(puzzle)
                }
                .buttonStyle(BrandPrimaryButtonStyle(expandHorizontally: true))
                .optionalAccessibilityIdentifier(A11yID.shoppingModeOpenPuzzleButton)
                .accessibilityLabel("Open puzzle")
                .accessibilityHint("Opens this puzzle in your collection")

                if showsScanAnother {
                    Button("Scan another") {
                        onScanAnother()
                    }
                    .buttonStyle(BrandSecondaryButtonStyle(expandHorizontally: true))
                    .accessibilityLabel("Scan another barcode")
                }
            }
        case .noMatch(let barcode):
            VStack(spacing: DS.Spacing.s2) {
                Button("Add this puzzle") {
                    onAddPuzzle(barcode)
                }
                .buttonStyle(BrandPrimaryButtonStyle(expandHorizontally: true))
                .optionalAccessibilityIdentifier(A11yID.shoppingModeAddPuzzleButton)
                .accessibilityLabel("Add this puzzle")
                .accessibilityHint("Opens quick add with this barcode")

                if showsScanAnother {
                    Button("Scan another") {
                        onScanAnother()
                    }
                    .buttonStyle(BrandSecondaryButtonStyle(expandHorizontally: true))
                    .optionalAccessibilityIdentifier(A11yID.shoppingModeScanAnotherButton)
                    .accessibilityLabel("Scan another barcode")
                }
            }
        }
    }

    private var borderColor: Color {
        switch result {
        case .match:
            return Brand.accent
        case .noMatch:
            return Brand.accentWarm
        }
    }

    private var accessibilityIdentifier: String {
        switch result {
        case .match:
            return A11yID.shoppingModeMatchCard
        case .noMatch:
            return A11yID.shoppingModeNoMatchCard
        }
    }

    @ViewBuilder
    private func puzzleThumbnail(for puzzle: Puzzle) -> some View {
        Group {
            if let image = puzzle.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.title)
                    .foregroundStyle(Brand.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Brand.cardElevated)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .accessibilityHidden(true)
    }
}
