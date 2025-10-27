# Razzil

A wrapper around the [StoreKit 2](https://developer.apple.com/storekit/) APIs used throughout MO Studios iOS projects.

## Install

Install using Swift Package Manager.

## Usage

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
