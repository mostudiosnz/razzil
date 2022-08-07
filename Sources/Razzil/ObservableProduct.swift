import Combine
import Raigor
import Gondar
import StoreKit

public protocol TransactionVerifying {
    var logger: Logger { get }
    func processTransaction(given verificationResult: VerificationResult<Transaction>) async
    @MainActor func processVerifiedTransaction(_ verifiedTransaction: Transaction)
}

public extension TransactionVerifying {
    func processTransaction(given verificationResult: VerificationResult<Transaction>) async {
        switch verificationResult {
        case .verified(let verifiedTransaction):
            await processVerifiedTransaction(verifiedTransaction)
            await verifiedTransaction.finish()
        case .unverified(let unverifiedTransaction, let error):
            logger.error(error)
            await unverifiedTransaction.finish()
        }
    }
}

public protocol PurchaseTracking {
    var tracker: Tracker { get }
    func trackPurchaseStarted(for product: Product)
    func trackPurchaseCompleted(with transaction: Transaction)
}

public extension PurchaseTracking {
    func trackPurchaseStarted(for product: Product) {
        tracker.track(event: PurchaseStartedEvent())
    }
    func trackPurchaseCompleted(with transaction: Transaction) {
        tracker.track(event: PurchaseCompletedEvent())
    }
}

public enum ProductState: Identifiable, Equatable {
    case initial
    case available(Product)
    case transacting(Product)
    case pending(Product)
    case failed(Product)
    case purchased(Transaction)
    
    public var id: String {
        switch self {
        case .initial: return "initial"
        case .available: return "available"
        case .transacting: return "transacting"
        case .pending: return "pending"
        case .failed: return "failed"
        case .purchased: return "purchased"
        }
    }
}

extension ProductState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .initial: return "initial"
        case .available(let product): return "available \(product.id)"
        case .transacting(let product): return "transacting \(product.id)"
        case .pending(let product): return "pending \(product.id)"
        case .failed(let product): return "failed \(product.id)"
        case .purchased(let transaction): return "purchased \(transaction.productID)"
        }
    }
}

public protocol ObservableProduct: AnyObject, TransactionVerifying, PurchaseTracking where ProductId: Identifiable, ProductId: RawRepresentable {
    associatedtype ProductId
    var id: ProductId { get }
    var state: ProductState { get set }
}

public extension ObservableProduct {
    func purchase() {
        guard case .available(let product) = state else { return }
        trackPurchaseStarted(for: product)
        Task { [product, weak self] in await self?.purchase(product: product) }
    }
    
    private func purchase(product: Product) async {
        await updatePurchaseState(to: .transacting(product))
        do {
            let purchaseResult = try await product.purchase()
            switch purchaseResult {
            case .success(let transactionResult):
                await processTransaction(given: transactionResult)
            case .pending:
                await updatePurchaseState(to: .pending(product))
            case .userCancelled:
                await updatePurchaseState(to: .available(product))
            @unknown default:
                await updatePurchaseState(to: .failed(product))
                try await Task.sleep(seconds: 1) // reset the product after failure
                await updatePurchaseState(to: .available(product))
            }
        } catch {
            await updatePurchaseState(to: .available(product))
            logger.error(error)
        }
    }
    
    @MainActor
    func processVerifiedTransaction(_ verifiedTransaction: Transaction) {
        let newProductState: ProductState
        switch state {
        case .initial, .purchased:
            newProductState = .purchased(verifiedTransaction)
            updatePurchaseState(to: .purchased(verifiedTransaction))
        case .available(let product), .transacting(let product), .pending(let product), .failed(let product):
            newProductState = verifiedTransaction.revocationDate == nil
            ? .purchased(verifiedTransaction)
            : .failed(product)
        }
        updatePurchaseState(to: newProductState)
        // Don't track purchase completed if original purchase date is outside 60 seconds
        guard case
            .purchased(let transaction) = newProductState,
            -(transaction.originalPurchaseDate.timeIntervalSinceNow) <= 60 else {
            return
        }
        trackPurchaseCompleted(with: transaction)
    }
        
    @MainActor
    private func updatePurchaseState(to newState: ProductState) {
        guard newState != state else { return }
        state = newState
    }
}

private extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: TimeInterval) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
