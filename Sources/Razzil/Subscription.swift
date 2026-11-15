import StoreKit

/// An app's auto-renewable subscriptions, identified by their StoreKit product IDs.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct Subscription: Sendable {
    private let productIDs: Set<String>

    /// Include legacy product IDs if existing subscribers can still use them.
    public init(productIDs: some Sequence<String>) {
        self.productIDs = Set(productIDs)
    }

    /// Whether StoreKit reports a verified current entitlement for any configured subscription.
    /// Includes billing grace periods and App Store Family Sharing entitlements.
    public var isSubscribed: Bool {
        get async {
            guard !productIDs.isEmpty else { return false }

            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result,
                   matches(transaction),
                   transaction.revocationDate == nil,
                   !transaction.isUpgraded {
                    return true
                }
            }
            return false
        }
    }

    /// Delivers the current subscription status for each verified matching transaction update.
    /// Read `isSubscribed` separately for the initial value. This method runs until its task is cancelled.
    /// Apply the status inside `onUpdate`. Razzil finishes the transaction after the callback returns.
    public func observeUpdates(_ onUpdate: @Sendable (Bool) async -> Void) async {
        guard !productIDs.isEmpty else { return }

        for await result in Transaction.updates {
            guard case .verified(let transaction) = result, matches(transaction) else { continue }

            let subscribed = await isSubscribed
            guard !Task.isCancelled else { return }
            await onUpdate(subscribed)
            guard !Task.isCancelled else { return }
            await transaction.finish()
        }
    }

    private func matches(_ transaction: Transaction) -> Bool {
        transaction.productType == .autoRenewable && productIDs.contains(transaction.productID)
    }
}
