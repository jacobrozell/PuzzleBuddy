//
//  BarcodeScannerTorchButton.swift
//  Puzzle Buddy
//

import AVFoundation
import SwiftUI

struct BarcodeScannerTorchButton: View {
    @State private var isOn = false

    private var torchAvailable: Bool {
        guard let device = AVCaptureDevice.default(for: .video) else { return false }
        return device.hasTorch
    }

    var body: some View {
        Button {
            toggleTorch()
        } label: {
            Image(systemName: isOn ? "flashlight.on.fill" : "flashlight.off.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.45), in: Circle())
        }
        .accessibilityLabel(isOn ? "Turn flash off" : "Turn flash on")
        .accessibilityHint("Helps scan barcodes in dim lighting")
        .opacity(torchAvailable ? 1 : 0)
        .disabled(!torchAvailable)
        .onDisappear {
            setTorch(on: false)
        }
    }

    private func toggleTorch() {
        setTorch(on: !isOn)
        isOn.toggle()
    }

    private func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            isOn = false
        }
    }
}
