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

    @State private var scanResult: BarcodeScanResult?
    @State private var showSuccessFlash = false
    @State private var scanSessionID = UUID()
    @State private var scansTotal = 0
    @State private var duplicatesFound = 0

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
                        if scansTotal > 0 {
                            shoppingSessionBanner
                                .padding(.top, DS.Spacing.s2)
                        }

                        Spacer()

                        BarcodeScannerGuidanceOverlay()
                    }

                    VStack {
                        HStack {
                            Spacer()
                            BarcodeScannerTorchButton()
                                .padding(DS.Spacing.s4)
                        }
                        Spacer()
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

                    BarcodeScanResultCard(
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

    private var shoppingSessionBanner: some View {
        let newCount = scansTotal - duplicatesFound
        return Text("\(scansTotal) scanned · \(duplicatesFound) duplicate\(duplicatesFound == 1 ? "" : "s") · \(newCount) new")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s2)
            .background(.black.opacity(0.55), in: Capsule())
            .accessibilityLabel("\(scansTotal) barcodes scanned, \(duplicatesFound) duplicates, \(newCount) not in collection")
    }

    private func handleScan(_ raw: String) {
        guard let normalized = BarcodeNormalizer.normalize(raw) ?? optionalDigits(from: raw) else { return }

        scansTotal += 1

        if let match = ps.findPuzzle(matchingBarcode: normalized) {
            duplicatesFound += 1
            BarcodeScanFeedback.duplicateFound()
            withAnimation(reduceMotion ? nil : .default) {
                scanResult = .match(match)
            }
            announceMatch(match)
            AppLog.shared.info(.puzzles, eventName: "shopping_scan_match", message: "Duplicate found while shopping.")
            return
        }

        BarcodeScanFeedback.scanAccepted()
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
