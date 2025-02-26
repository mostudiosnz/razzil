//
//  AppProductsManager.swift
//  Razzil
//
//  Created by jk on 2025-02-25.
//

import SwiftUI

public typealias APM = AppProductsManager

@propertyWrapper public struct AppProductsManager: DynamicProperty {
    public var wrappedValue: ProductsManager
    
    public init() {
        self.wrappedValue = ProductsManager.shared
    }
}
