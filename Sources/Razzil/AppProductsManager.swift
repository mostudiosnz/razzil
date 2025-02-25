//
//  AppProductsManager.swift
//  Razzil
//
//  Created by jk on 2025-02-25.
//

import SwiftUI

@propertyWrapper public struct AppProductsManager: DynamicProperty {
    public var wrappedValue: ProductsManager
    
    public init(ids identifiers: [String]) {
        self.wrappedValue = DefaultProductsManager(for: identifiers)
    }
}
