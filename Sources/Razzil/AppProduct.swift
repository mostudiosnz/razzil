//
//  AppProduct.swift
//  Razzil
//
//  Created by jk on 2025-10-24.
//

import StoreKit

public enum AppProduct: Sendable, Identifiable, Equatable, Hashable, CustomDebugStringConvertible {
    case available(product: Product)
    case active(product: Product, transaction: Transaction)
    public var id: String {
        switch self {
        case let .available(product): return product.id
        case let .active(product, _): return product.id
        }
    }
    public var isAvailable: Bool {
        switch self {
        case .available: return true
        case .active: return false
        }
    }
    public var isActive: Bool {
        switch self {
        case .active: return true
        case .available: return false
        }
    }
    public static func == (lhs: AppProduct, rhs: AppProduct) -> Bool {
        switch (lhs, rhs) {
            case let (.available(l), .available(r)): return l == r
            case let (.active(lp, lt), .active(rp, rt)): return lp == rp && lt == rt
            default: return false
        }
    }
    public var debugDescription: String {
        switch self {
        case let .available(product): return "available: " + product.id
        case let .active(product, transaction): return "active: " + product.id + " transaction date: " + transaction.purchaseDate.description
        }
    }
}
