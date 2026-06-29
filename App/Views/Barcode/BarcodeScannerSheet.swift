//
//  BarcodeScannerSheet.swift
//  Puzzle Buddy
//

import SwiftUI

struct BarcodeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onBarcodeScanned: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if BarcodeScannerSupport.isAvailable {
                    ZStack(alignment: .bottom) {
                        BarcodeScannerView { barcode in
                            BarcodeScanFeedback.scanAccepted()
                            onBarcodeScanned(barcode)
                            dismiss()
                        }
                        .ignoresSafeArea()

                        BarcodeScannerGuidanceOverlay()
                            .ignoresSafeArea(edges: .bottom)
                    }
                    .overlay(alignment: .topTrailing) {
                        BarcodeScannerTorchButton()
                            .padding(DS.Spacing.s4)
                    }
                } else {
                    ContentUnavailableView(
                        "Scanner unavailable",
                        systemImage: "barcode.viewfinder",
                        description: Text("Barcode scanning needs a device with a camera. You can still enter a barcode manually in the add form.")
                    )
                }
            }
            .navigationTitle("Scan barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .optionalAccessibilityIdentifier(A11yID.barcodeScannerCancel)
                }
            }
            .accessibilityIdentifier(A11yID.barcodeScannerSheet)
        }
    }
}
