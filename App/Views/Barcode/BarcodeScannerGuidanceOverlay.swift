//
//  BarcodeScannerGuidanceOverlay.swift
//  Puzzle Buddy
//

import SwiftUI

struct BarcodeScannerGuidanceOverlay: View {
    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            Text("Align the barcode inside the frame.")
                .font(.subheadline.weight(.medium))
            Text("Tilt the box to reduce glare on shiny wrap.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.55))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Align the barcode inside the frame. Tilt the box to reduce glare on shiny wrap.")
    }
}
