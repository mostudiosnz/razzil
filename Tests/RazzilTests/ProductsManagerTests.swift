//
//  ProductsManagerTests.swift
//  Razzil
//
//  Created by jk on 2025-02-25.
//

import Testing
@testable import Razzil

struct ProductsManagerTests {
    var pm: ProductsManager
    init() async throws {
        pm = DefaultProductsManager(ids: ["id1", "id2"])
        await pm.initialize()
    }
    
    @Test func example() async {
        await #expect(pm.initialized == true)
        await #expect(pm.products.count == 0)
    }
}
