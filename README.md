# Razzil

A wrapper around the [StoreKit 2](https://developer.apple.com/storekit/) APIs used throughout MO Studios iOS projects.

## Install

Install using Swift Package Manager.

## Usage

#### Check subscription access

```swift
import Razzil

let subscription = Subscription(productIDs: ["monthly.product.id", "yearly.product.id"])
let isSubscribed = await subscription.isSubscribed
```

Configure each app with the auto-renewable product IDs that grant access, including legacy IDs that are still honored. The check uses verified StoreKit entitlements and includes billing grace periods and eligible App Store Family Sharing. Existing one-time purchases can continue to grant access through the app's purchase rules.

Read `isSubscribed` at launch and again after a successful purchase or restore. The check queries StoreKit on each read and works independently of `Store.initialize()`.

To receive transactions that arrive outside the upsell sheet, start a single listener in an app-lifetime task at launch:

```swift
let subscriptionUpdates = Task {
    await subscription.observeUpdates { isSubscribed in
        await appStore.updateSubscriptionStatus(isSubscribed)
    }
}
```

The callback receives a fresh Boolean for each verified update matching the configured subscriptions. Apply the value in the callback before returning so Razzil can finish the transaction. Use one listener to process these product IDs, and cancel `subscriptionUpdates` when its owner no longer needs it. A verified purchase in `onInAppPurchaseCompletion` still goes through the app's purchase handler.

For a shared child profile, use this Boolean for the current App Store account's subscription entitlement. Use the app's profile authorization to decide whether each caregiver has access.

#### With SwiftUI environment

```swift
import Razzil
import SwiftUI

private struct StoreKey: EnvironmentKey {
    static let defaultValue = Store(productIds: ["id1", "id2"])
}

extension EnvironmentValues {
    var store: ProductsManager {
        get { self[StoreKey.self] }
    }
}

struct MyView: View {
    @Environment(\.store) var store
    var body: some View {
        VStack {
        
        }
        .task {
            try? await store.initialize()
            let products = await store.products
        }
    }
}
```

#### Through a singleton

```swift
import Combine
import Razzil
import SwiftUI

let singletonGlobalStore = Store(productIds: ["id1", "id2"])

class MyViewModel: ObservableObject {
    init(store: Store = singletonGlobalStore) {
        //
    }
}
```

## Release

Release using git tags. For example:
```
git tag -a "1.1.0" -m "update observable products to hold ids"
git push origin 1.1.0
```
