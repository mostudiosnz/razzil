//
//  ProductsManager.swift
//  Razzil
//
//  Created by jk on 2025-02-25.
//

import Combine
import StoreKit

public enum AppProduct: Sendable, Identifiable, Equatable, CustomDebugStringConvertible {
    case purchased(Product)
    case subscribed(Product)
    case available(Product)
    public var id: String {
        switch self {
        case .purchased(let product): return product.id
        case .subscribed(let product): return product.id
        case .available(let product): return product.id
        }
    }
    public var data: Product {
        switch self {
        case .purchased(let product): return product
        case .subscribed(let product): return product
        case .available(let product): return product
        }
    }
    public var isPurchased: Bool {
        switch self {
        case .purchased: return true
        case .subscribed: return false
        case .available: return false
        }
    }
    public var isSubscribed: Bool {
        switch self {
        case .purchased: return false
        case .subscribed: return true
        case .available: return false
        }
    }
    public var isAvailable: Bool {
        switch self {
        case .purchased: return false
        case .subscribed: return false
        case .available: return true
        }
    }
    public static func == (lhs: AppProduct, rhs: AppProduct) -> Bool {
        switch (lhs, rhs) {
        case (.purchased(let l), .purchased(let r)): return l == r
        case (.subscribed(let l), .subscribed(let r)): return l == r
        case (.available(let l), .available(let r)): return l == r
        default: return false
        }
    }
    public var debugDescription: String {
        switch self {
        case .purchased(let product): return "purchased: " + product.id
        case .subscribed(let product): return "subscribed: " + product.id
        case .available(let product): return "available: " + product.id
        }
    }
}

public enum InitializeError: Error {
    case fetchingProduct(StoreKitError)
    case completeFailure(Error)
}

public enum PurchaseError: Error {
    case storeFailure(StoreKitError)
    case productIssue(Product.PurchaseError)
    case completeFailure(Error)
}

extension PassthroughSubject: @unchecked @retroactive Sendable {}

public actor ProductsManager: GlobalActor {
    public static let shared = ProductsManager()
    
    public private(set) var products: [AppProduct]
    public private(set) var initialized = false
    public let productUpdate = PassthroughSubject<(oldValue: AppProduct, newValue: AppProduct), Never>()
    private var updates: Task<Void, Never>? // this Task never finishes (async sequence runs forever until cancelled)
    
    public init() {
        self.products = []
    }
    
    public func initialize(ids identifiers: [String]) async -> Result<Void, InitializeError> {
        do {
            // 1. fetch all products in available state
            let storefrontProducts = try await Product.products(for: identifiers)
            products = storefrontProducts.map { .available($0) }
            // 2. fetch current entitlements and update products accordingly
            for id in identifiers {
                guard let entitlement = await Transaction.currentEntitlement(for: id)
                else { continue }
                await processVerificationResult(result: entitlement)
            }
            // 3. listen for any asynchronous updates (long running)
            updates = Task(priority: .background) {
                await listenForUpdates()
            }
            // 4. finalize initialization
            initialized = true
            return .success(())
        } catch let storeKitError as StoreKitError {
            return .failure(.fetchingProduct(storeKitError))
        } catch {
            return .failure(.completeFailure(error))
        }
    }
    
    public func purchase(product: AppProduct) async -> Result<Void, PurchaseError> {
        do {
            let result = try await product.data.purchase()
            switch result {
            case .pending:
                return .failure(.productIssue(.purchaseNotAllowed))
            case .success(let result):
                await processVerificationResult(result: result)
                return .success(())
            case .userCancelled:
                return .failure(.storeFailure(.userCancelled))
            @unknown default:
                return .failure(.completeFailure(StoreKitError.unknown))
            }
        } catch let storeKitError as StoreKitError {
            return .failure(.storeFailure(storeKitError))
        } catch let productPurchaseError as Product.PurchaseError {
            return .failure(.productIssue(productPurchaseError))
        } catch {
            return .failure(.completeFailure(error))
        }
    }
    
    func listenForUpdates() async {
        for await update in Transaction.updates {
            await processVerificationResult(result: update)
        }
    }
    
    func processVerificationResult(result: VerificationResult<Transaction>) async {
        switch result {
        case .verified(let transaction):
            await processVerified(transaction: transaction)
        case .unverified(let transaction, let error):
            await processUnverified(transaction: transaction, and: error)
        }
    }
    
    func processVerified(transaction: Transaction) async {
        struct Matching {
            let i: Int
            let product: AppProduct
        }
        var matching: Matching? = nil
        for (i, product) in products.enumerated() {
            guard product.id == transaction.productID else { continue }
            let p = await transaction.product ?? product.data
            let new: AppProduct
            switch transaction.productType {
            case .nonConsumable, .consumable:
                new = transaction.isPurchased ? .purchased(p) : .available(p)
            case .nonRenewable, .autoRenewable:
                new = await transaction.isSubscribed ? .subscribed(p) : .available(p)
            default:
                new = .available(p)
            }
            matching = Matching(i: i, product: new)
        }
        if let matching, matching.product != products[matching.i] {
            if initialized {
                // publish updates of new transactions
                productUpdate.send((products[matching.i], matching.product))
            }
            products[matching.i] = matching.product
        }
        await transaction.finish()
    }

    func processUnverified(transaction: Transaction, and error: VerificationResult<Transaction>.VerificationError) async {
        /// just handle unverified transactions same as verified. not too worried about fraud at the moment
        await processVerified(transaction: transaction)
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
    var isPurchased: Bool {
        return !revocationDate.isExpired && !expirationDate.isExpired
    }
    var isSubscribed: Bool {
        get async {
            guard let status = await subscriptionStatus else {
                return false
            }
            switch status.state {
            case .subscribed: return true
            default: return false
            }
        }
    }
    var product: Product? {
        get async {
            let products = try? await Product.products(for: [productID])
            return products?.first
        }
    }
}
