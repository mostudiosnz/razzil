# Razzil

A wrapper around the [StoreKit 2](https://developer.apple.com/storekit/) APIs used throughout MO Studios iOS projects.

## Install

Install using Swift Package Manager.

## Usage

All In-App Purchases consist around 2 concepts: Store & Product. 

It is suggested to create a singleton `Store` object and let it conform to the `ObservableStore` protocol.

Next declare your Products and make references to the products from the store.

```
// Store.swift

import Razzil
import StoreKit

final class Store: ObservableStore {
  static let shared = Store()
  @Published var state: StoreState = .initial
  
  // Reference the products
  @Published var productOne = ProductOne()
  @Published var productTwo = ProductTwo()
  
  init() {
    // Call StoreKit APIs to load the products and also handle purchase restoration
    ...
  }
}
```

And to declare the products:
```
// Products.swift

import Razzil

enum AppProduct: String, Identifiable {
  case productOne
  case productTwo
  var id: String { rawValue }
}

class ProductOne: ObservableObject, ObservableProduct {
  let id: AppProduct
  @Published var state: ProductState
}

class ProductTwo: ObservableObject, ObservableProduct {
  let id: AppProduct
  @Published var state: ProductState
}
```
