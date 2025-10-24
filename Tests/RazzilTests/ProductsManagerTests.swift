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
        pm = ProductsManager(productIds: ["id1", "id2"])
    }
    
    @Test func testInitialize() async {
        await #expect(throws: SynchronizeError.self, "unknown product id") {
            try await pm.initialize()
        }
        await #expect(pm.products.count == 0)
    }
}
