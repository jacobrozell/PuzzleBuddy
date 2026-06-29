//
//  BarcodeScannerView.swift
//  Puzzle Buddy
//

import SwiftUI
import VisionKit

struct BarcodeScannerView: UIViewControllerRepresentable {
    let onBarcodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [
                .barcode(symbologies: [.ean8, .ean13, .upce, .code39, .code128])
            ],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        Task { @MainActor in
            guard DataScannerViewController.isSupported, DataScannerViewController.isAvailable else { return }
            if !uiViewController.isScanning {
                try? uiViewController.startScanning()
            }
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcodeScanned: onBarcodeScanned)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onBarcodeScanned: (String) -> Void
        private var lastScanDate = Date.distantPast

        init(onBarcodeScanned: @escaping (String) -> Void) {
            self.onBarcodeScanned = onBarcodeScanned
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard let item = addedItems.first else { return }
            let now = Date()
            guard now.timeIntervalSince(lastScanDate) >= 1.0 else { return }

            switch item {
            case .barcode(let barcode):
                guard let payload = barcode.payloadStringValue else { return }
                lastScanDate = now
                dataScanner.stopScanning()
                onBarcodeScanned(payload)
            default:
                break
            }
        }
    }
}

@MainActor
enum BarcodeScannerSupport {
    static var isAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
}
