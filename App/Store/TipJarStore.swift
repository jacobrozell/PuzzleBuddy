//
//  TipJarStore.swift
//  Puzzle Buddy
//

import Foundation
import StoreKit

@MainActor
final class TipJarStore: ObservableObject {
    static let shared = TipJarStore()

    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var didSucceed = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var purchasingProductID: String?

    private var updatesTask: Task<Void, Never>?

    func start() {
        guard !UITestSupport.isRunningUnderTest else { return }
        guard updatesTask == nil else { return }
        updatesTask = Task { await listenForUpdates() }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let loaded = try await Product.products(for: TipJarProductIDs.all)
            products = loaded.sorted { TipJarProductIDs.rank($0.id) < TipJarProductIDs.rank($1.id) }
            if products.isEmpty {
                statusMessage = TipJarCopy.unavailable
            } else if statusMessage == TipJarCopy.unavailable {
                statusMessage = nil
            }
        } catch {
            products = []
            statusMessage = TipJarCopy.unavailable
        }
    }

    func purchase(_ product: Product) async {
        purchasingProductID = product.id
        defer { purchasingProductID = nil }
        didSucceed = false
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try Self.verified(verification)
                await transaction.finish()
                didSucceed = true
                statusMessage = TipJarCopy.thankYou
                AppLog.shared.info(
                    .ui,
                    eventName: "tip_jar_purchase_completed",
                    message: "Tip purchase finished.",
                    metadata: ["product_id": transaction.productID]
                )
            case .userCancelled:
                break
            case .pending:
                statusMessage = TipJarCopy.pending
            @unknown default:
                statusMessage = TipJarCopy.failed
            }
        } catch {
            statusMessage = TipJarCopy.failed
        }
    }

    static func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw TipJarError.unverified
        case .verified(let value):
            return value
        }
    }

    private func listenForUpdates() async {
        for await result in Transaction.updates {
            guard let transaction = try? Self.verified(result) else { continue }
            guard TipJarProductIDs.all.contains(transaction.productID) else { continue }
            await transaction.finish()
        }
    }
}
