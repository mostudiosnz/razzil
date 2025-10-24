//
//  ProductsManager.swift
//  Razzil
//
//  Created by jk on 2025-02-25.
//

import Combine
import StoreKit

extension PassthroughSubject: @unchecked @retroactive Sendable {}

public enum PurchaseEvents {
    /// This event only triggers if purchasing through `ProductsManager`
    /// and does not trigger if using StoreKit provided SwiftUI purchase views.
    case started(AppProduct)
    /// Triggered when a product changes from either `available` or `scheduled` state to `active`
    case purchased(AppProduct, Transaction)
    /// Triggered when a product changes from either `active` or `scheduled` state back to `available`
    case relisted(AppProduct)
    /// This event only triggers if purchasing through `ProductsManager`
    /// and does not trigger if using StoreKit provided SwiftUI purchase views.
    case failed(AppProduct, ProductsManager.PurchaseError)
}

public actor ProductsManager {
    public enum SyncError: Error {
        case unknownProductId(id: String)
    }
    public enum PurchaseError: Error {
        case storeFailure(StoreKitError)
        case productIssue(Product.PurchaseError)
        case completeFailure(Error)
    }
    public private(set) var products: [AppProduct]
    private let ids: [String]
    private let defaults: UserDefaults!
    public nonisolated let purchaseEvents = PassthroughSubject<PurchaseEvents, Never>()
    private var updates: Task<Void, Never>? // this Task never finishes (async sequence runs forever until cancelled)
    
    public init(
        productIds: [String],
        suiteName: String = "app.mostudios.razzil"
    ) {
        self.products = []
        self.ids = productIds
        self.defaults = UserDefaults(suiteName: suiteName)!
    }
    
    public func initialize() async throws(ProductsManager.SyncError) {
        try await synchronize()
        updates = Task(priority: .background) {
            await listenForUpdates()
        }
    }
    
    public func purchase(product: AppProduct) async throws(ProductsManager.PurchaseError) {
        purchaseEvents.send(.started(product))
        guard case let .available(availableProduct) = product else {
            let error = PurchaseError.productIssue(.purchaseNotAllowed)
            purchaseEvents.send(.failed(product, error))
            throw error
        }
        do {
            let result = try await availableProduct.purchase()
            switch result {
            case .pending:
                throw PurchaseError.productIssue(.purchaseNotAllowed)
            case .success:
                try await synchronize()
            case .userCancelled:
                throw PurchaseError.storeFailure(.userCancelled)
            @unknown default:
                throw PurchaseError.completeFailure(StoreKitError.unknown)
            }
        } catch let purchaseError as PurchaseError {
            purchaseEvents.send(.failed(product, purchaseError))
            throw purchaseError
        } catch let storeKitError as StoreKitError {
            let purchaseError = PurchaseError.storeFailure(storeKitError)
            purchaseEvents.send(.failed(product, purchaseError))
            throw purchaseError
        } catch let productPurchaseError as Product.PurchaseError {
            let purchaseError = PurchaseError.productIssue(productPurchaseError)
            purchaseEvents.send(.failed(product, purchaseError))
            throw purchaseError
        } catch {
            let purchaseError = PurchaseError.completeFailure(error)
            purchaseEvents.send(.failed(product, purchaseError))
            throw purchaseError
        }
    }
    
    private func listenForUpdates() async {
        for await update in Transaction.updates {
            let transaction = switch update {
            case let .verified(transaction):
                transaction
            case let .unverified(transaction, _):
                transaction
            }
            await transaction.finish()
            try? await synchronize()
        }
    }
    
    private func synchronize() async throws(ProductsManager.SyncError) {
        var events: [PurchaseEvents] = []
        var updatedProducts: [AppProduct] = []
        for id in ids {
            if let active = await currentlyEntitled(id: id) {
                let activeProduct = AppProduct.active(product: active.product, transaction: active.transaction)
                if productHasUpdated(activeProduct, from: defaults) {
                    events.append(.purchased(activeProduct, active.transaction))
                }
                updatedProducts.append(activeProduct)
            } else if let available = await Product.product(id: id) {
                let availableProduct = AppProduct.available(product: available)
                if productHasUpdated(availableProduct, from: defaults) {
                    events.append(.relisted(availableProduct))
                }
                updatedProducts.append(availableProduct)
            } else {
                throw .unknownProductId(id: id)
            }
        }
        products = updatedProducts
        events.forEach(purchaseEvents.send)
        save(into: defaults)
    }
    
    private func currentlyEntitled(id: String) async -> (product: Product, transaction: Transaction)? {
        var transaction: Transaction?
        if #available(iOS 18.4, *) {
            for await result in Transaction.currentEntitlements(for: id) {
                if transaction != nil { continue }
                transaction = result.unsafePayloadValue
            }
        } else {
            let result = await Transaction.currentEntitlement(for: id)
            transaction = result?.unsafePayloadValue
        }
        guard
            let transaction,
            await transaction.isActive,
            let product = await transaction.product
        else { return nil }
        return (product: product, transaction: transaction)
    }
}

private extension Optional where Wrapped == Date {
    var isRevoked: Bool {
        guard let date = self else { return false }
        let comparison = date.compare(.now)
        switch comparison {
        case .orderedAscending: return true
        case .orderedSame, .orderedDescending: return false
        }
    }
    var isExpired: Bool {
        guard let date = self else { return false }
        let comparison = date.compare(.now)
        switch comparison {
        case .orderedAscending: return true
        case .orderedSame, .orderedDescending: return false
        }
    }
}

private extension Transaction {
    var isActive: Bool {
        get async {
            guard let status = await subscriptionStatus else {
                // active for non-subscription purchases
                return !revocationDate.isExpired && !expirationDate.isExpired
            }
            // active for subscriptions
            switch status.state {
            case .subscribed: return true
            default: return false
            }
        }
    }
    var product: Product? {
        get async {
            await Product.product(id: productID)
        }
    }
}

private extension Product {
    static func product(id: String) async -> Product? {
        do {
            let products = try await Product.products(for: [id])
            return products.first
        } catch {
            return nil
        }
    }
}
