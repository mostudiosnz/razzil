# Razzil

A wrapper around the [StoreKit 2](https://developer.apple.com/storekit/) APIs used throughout MO Studios iOS projects.

## Install

Install using Swift Package Manager.

## Usage

Either use the `AppProductsManager` property wrapper (easiest and recommended) or create your own `DefaultProductsManager` actor instance and manage it.

Using the `AppProductsManager` property wrapper:

```swift
import Razzil

struct MyViewHandlingProducts: View {
    @AppProductsManager(ids: ["product_id1", "product_id2"]) var productsManager
    @State var products: [AppProduct] = [] // keep a local state to make it easier to drive UI updates
  
    var body: some View {
        VStack {
            ForEach(products) { product in
                Button(product.id) {
                    Task { @MainActor in
                        let result = await productsManager.purchase(product: product)
                        switch result {
                        case .success:
                            // handle purchase success
                            products = await productsManager.products // updating the state is a good idea
                        case .failure(let error)
                            // handle error handling of `Razzil.PurchaseError`
                        }
                    }
                }
                .disabled(!product.isAvailable)
            }
        }
        .task {
            let result = await productsManager.initialize() // the products manager must be initialized at some point before use
            switch result {
            case .success:
                products = await productsManager.products
            case .failure(let error):
                // handle error handling of `Razzil.InitializeError`
            }
        }
    }
}
```

Managing your own actor instace of `ProductsManager`:
```swift
import Razzil

class MyClassHandlingProducts {
    var productsManager: ProductsManager
    init() {
        self.productsManager = DefaultProductsManager(ids: ["product_id1", "product_id2"])
    }
}
```

## Release

Release using git tags. For example:
```
git tag -a "1.1.0" -m "update observable products to hold ids"
git push origin 1.1.0
```
