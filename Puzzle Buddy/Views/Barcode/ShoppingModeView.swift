//
//  ShoppingModeView.swift
//  Puzzle Buddy
//

import SwiftUI

struct ShoppingModeView: View {
    @ObservedObject var ps: PuzzleStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onAddPuzzle: (String) -> Void
    let onOpenPuzzle: (Puzzle) -> Void

    @State private var scanResult: ShoppingScanResult?
    @State private var showSuccessFlash = false
    @State private var scanSessionID = UUID()

    var body: some View {
        NavigationStack {
            ZStack {
                if BarcodeScannerSupport.isAvailable {
                    BarcodeScannerView { raw in
                        handleScan(raw)
                    }
                    .id(scanSessionID)
                    .ignoresSafeArea()

                    VStack {
                        Spacer()
                        BarcodeScannerGuidanceOverlay()
                    }
                } else {
                    ContentUnavailableView(
                        "Scanner unavailable",
                        systemImage: "barcode.viewfinder",
                        description: Text("Barcode scanning needs a device with a camera. Enter barcodes manually when adding a puzzle.")
                    )
                }

                if showSuccessFlash, !reduceMotion {
                    Color.green.opacity(0.25)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                if let currentScanResult = scanResult {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .accessibilityHidden(true)

                    ShoppingScanResultCard(
                        result: currentScanResult,
                        onOpenPuzzle: { puzzle in
                            dismiss()
                            onOpenPuzzle(puzzle)
                        },
                        onAddPuzzle: { barcode in
                            dismiss()
                            onAddPuzzle(barcode)
                        },
                        onScanAnother: {
                            scanResult = nil
                            scanSessionID = UUID()
                        }
                    )
                    .padding(DS.Spacing.s4)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: scanResult != nil)
            .navigationTitle("Check duplicate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .optionalAccessibilityIdentifier(A11yID.shoppingModeCancel)
                    .accessibilityLabel("Cancel shopping mode")
                }
            }
            .accessibilityIdentifier(A11yID.shoppingModeSheet)
        }
    }

    private func handleScan(_ raw: String) {
        guard let normalized = BarcodeNormalizer.normalize(raw) ?? optionalDigits(from: raw) else { return }

        if let match = ps.findPuzzle(matchingBarcode: normalized) {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            withAnimation(reduceMotion ? nil : .default) {
                scanResult = .match(match)
            }
            announceMatch(match)
            AppLog.shared.info(.puzzles, eventName: "shopping_scan_match", message: "Duplicate found while shopping.")
            return
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        if !reduceMotion {
            withAnimation(.easeOut(duration: 0.2)) {
                showSuccessFlash = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation {
                    showSuccessFlash = false
                }
            }
        }
        withAnimation(reduceMotion ? nil : .default) {
            scanResult = .noMatch(barcode: normalized)
        }
        UIAccessibility.post(notification: .announcement, argument: "Not in your collection. You can add this puzzle or scan another barcode.")
        AppLog.shared.info(.puzzles, eventName: "shopping_scan_no_match", message: "No duplicate while shopping.")
    }

    private func announceMatch(_ puzzle: Puzzle) {
        var announcement = "Already in your collection. \(puzzle.name)"
        if let pieces = puzzle.pieces {
            announcement += ", \(pieces) pieces"
        }
        announcement += ", \(puzzle.status.rawValue). Actions available: Open puzzle, Scan another."
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }

    private func optionalDigits(from raw: String) -> String? {
        let digits = raw.filter(\.isNumber)
        return digits.isEmpty ? nil : digits
    }
}

enum ShoppingScanResult {
    case match(Puzzle)
    case noMatch(barcode: String)
}

private struct ShoppingScanResultCard: View {
    let result: ShoppingScanResult
    let onOpenPuzzle: (Puzzle) -> Void
    let onAddPuzzle: (String) -> Void
    let onScanAnother: () -> Void

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
            Label("Safe to buy", systemImage: "bag.badge.plus")
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
                .buttonStyle(BrandPrimaryButtonStyle())
                .optionalAccessibilityIdentifier(A11yID.shoppingModeOpenPuzzleButton)
                .accessibilityLabel("Open puzzle")
                .accessibilityHint("Opens this puzzle in your collection")

                Button("Scan another") {
                    onScanAnother()
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Scan another barcode")
            }
        case .noMatch(let barcode):
            VStack(spacing: DS.Spacing.s2) {
                Button("Add this puzzle") {
                    onAddPuzzle(barcode)
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .optionalAccessibilityIdentifier(A11yID.shoppingModeAddPuzzleButton)
                .accessibilityLabel("Add this puzzle")
                .accessibilityHint("Opens quick add with this barcode")

                Button("Scan another") {
                    onScanAnother()
                }
                .buttonStyle(.bordered)
                .optionalAccessibilityIdentifier(A11yID.shoppingModeScanAnotherButton)
                .accessibilityLabel("Scan another barcode")
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
