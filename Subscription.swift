/*
MIT License

Copyright (c) 2022 MO STUDIOS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import StoreKit

/// An app's auto-renewable subscriptions, identified by StoreKit product IDs or a subscription group ID.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct Subscription: Sendable {
    private enum Scope: Sendable {
        case productIDs(Set<String>)
        case groupID(String)

        var isEmpty: Bool {
            switch self {
            case .productIDs(let ids): ids.isEmpty
            case .groupID(let id): id.isEmpty
            }
        }
    }

    private let scope: Scope

    /// Include legacy product IDs if existing subscribers can still use them.
    public init(productIDs: some Sequence<String>) {
        scope = .productIDs(Set(productIDs))
    }

    /// Include every auto-renewable product in this subscription group.
    public init(groupID: String) {
        scope = .groupID(groupID)
    }

    /// Whether StoreKit reports a verified current entitlement for any configured subscription.
    /// Includes billing grace periods and App Store Family Sharing entitlements.
    public var isSubscribed: Bool {
        get async {
            guard !scope.isEmpty else { return false }

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
        guard !scope.isEmpty else { return }

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
        guard transaction.productType == .autoRenewable else { return false }

        switch scope {
        case .productIDs(let ids): return ids.contains(transaction.productID)
        case .groupID(let id): return transaction.subscriptionGroupID == id
        }
    }
}
