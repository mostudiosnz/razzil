import Gondar
import StoreKit

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
