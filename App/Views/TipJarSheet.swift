//
//  TipJarSheet.swift
//  Puzzle Buddy
//

import StoreKit
import SwiftUI

struct TipJarSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: TipJarStore

    init(store: TipJarStore = .shared) {
        self.store = store
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if store.isLoading && store.products.isEmpty {
                        ProgressView("Loading tips")
                    } else if store.products.isEmpty {
                        Text(store.statusMessage ?? TipJarCopy.unavailable)
                    } else {
                        ForEach(store.products, id: \.id) { product in
                            productButton(product)
                        }
                    }
                } footer: {
                    Text(TipJarCopy.footer)
                }

                if store.didSucceed {
                    Section {
                        Label(TipJarCopy.thankYou, systemImage: "checkmark.circle.fill")
                            .accessibilityIdentifier(A11yID.settingsTipJarThankYou)
                    }
                } else if let statusMessage = store.statusMessage, !store.products.isEmpty {
                    Section {
                        Text(statusMessage)
                    }
                }
            }
            .navigationTitle(TipJarCopy.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .accessibilityIdentifier(A11yID.settingsTipJarCloseButton)
                }
            }
            .accessibilityIdentifier(A11yID.settingsTipJarSheet)
            .task { await store.loadProducts() }
        }
        .presentationDetents([.medium, .large])
    }

    private func productButton(_ product: Product) -> some View {
        Button {
            Task { await store.purchase(product) }
        } label: {
            HStack {
                Text(product.displayName)
                Spacer()
                if store.purchasingProductID == product.id {
                    ProgressView()
                } else {
                    Text(product.displayPrice)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(store.purchasingProductID != nil)
        .accessibilityIdentifier(
            A11yID.settingsTipJarProduct(TipJarProductIDs.accessibilitySuffix(for: product.id))
        )
        .accessibilityLabel("\(product.displayName), \(product.displayPrice)")
    }
}
