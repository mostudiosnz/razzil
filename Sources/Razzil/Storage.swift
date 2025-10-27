//
//  Storage.swift
//  Razzil
//
//  Created by jk on 2025-10-24.
//

import Foundation

fileprivate enum StoredStatus: Codable, Equatable {
    case available
    case active(purchaseDate: Date)
    init(product: StoreProduct) {
        switch product {
        case .available: self = .available
        case let .active(_, transaction): self = .active(purchaseDate: transaction.purchaseDate)
        }
    }
}

extension Store {
    func productHasUpdated(
        _ product: StoreProduct,
        from defaults: UserDefaults,
    ) -> Bool {
        guard let data = defaults.data(forKey: product.id) else {
            return false
        }
        do {
            let status = try JSONDecoder().decode(StoredStatus.self, from: data)
            return status != StoredStatus(product: product)
        } catch {
            return false
        }
    }
    func save(into defaults: UserDefaults) {
        for product in products {
            let status = StoredStatus(product: product)
            do {
                let data = try JSONEncoder().encode(status)
                defaults.set(data, forKey: product.id)
            } catch {
                defaults.removeObject(forKey: product.id)
            }
        }
    }
}
