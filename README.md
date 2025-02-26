# Razzil

A wrapper around the [StoreKit 2](https://developer.apple.com/storekit/) APIs used throughout MO Studios iOS projects.

## Install

Install using Swift Package Manager.

## Usage

Either use the `AppProductsManager` property wrapper (easiest and recommended) or manage the `ProductsManager` `GlobalActor` singleton yourself.

Using the `AppProductsManager` property wrapper:

```swift
import Razzil

struct MyViewHandlingProducts: View {
    @AppProductsManager var productsManager
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
        .onReceive(productsManager.updated.receive(on: DispatchQueue.main)) { _ in
            // if using StoreKit provided UI, listen for the updated publisher
            Task {
                products = await productsManager.products
            }
        }
        .task {
            let result = await productsManager.initialize(ids: ["product_id1", "product_id2"]) // the products manager must be initialized at some point before use
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

Handling the `ProductsManager` `GlobalActor` singleton instance:
```swift
import Razzil

class MyClassHandlingProducts {
    var productsManager = ProductsManager.shared
    
    func initialize() {
        Task {
            await productsManager.initialize(ids: ["product_id1", "product_id2"])
        }
    }
}
```

## Release

Release using git tags. For example:
```
git tag -a "1.1.0" -m "update observable products to hold ids"
git push origin 1.1.0
```
