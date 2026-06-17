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

    var body: some View {
        NavigationStack {
            ZStack {
                if BarcodeScannerSupport.isAvailable {
                    BarcodeScannerView { raw in
                        handleScan(raw)
                    }
                    .ignoresSafeArea()

                    VStack {
                        Spacer()
                        Text("Align the barcode on the puzzle box inside the frame.")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.black.opacity(0.55))
                            .accessibilityLabel("Align the barcode on the puzzle box inside the frame")
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

                if let scanResult {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .accessibilityHidden(true)

                    ShoppingScanResultCard(
                        result: scanResult,
                        onOpenPuzzle: { puzzle in
                            dismiss()
                            onOpenPuzzle(puzzle)
                        },
                        onAddPuzzle: { barcode in
                            dismiss()
                            onAddPuzzle(barcode)
                        },
                        onScanAnother: {
                            self.scanResult = nil
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
            Label("Already in your collection", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(Brand.accent)
        case .noMatch:
            Label("Not in your collection", systemImage: "questionmark.circle.fill")
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
            Text("Barcode \(barcode) is not saved in your collection yet.")
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
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

                Button("Scan another") {
                    onScanAnother()
                }
                .buttonStyle(.bordered)
            }
        case .noMatch(let barcode):
            VStack(spacing: DS.Spacing.s2) {
                Button("Add this puzzle") {
                    onAddPuzzle(barcode)
                }
                .buttonStyle(BrandPrimaryButtonStyle())
                .optionalAccessibilityIdentifier(A11yID.shoppingModeAddPuzzleButton)

                Button("Scan another") {
                    onScanAnother()
                }
                .buttonStyle(.bordered)
                .optionalAccessibilityIdentifier(A11yID.shoppingModeScanAnotherButton)
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
