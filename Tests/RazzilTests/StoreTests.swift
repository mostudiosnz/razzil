//
//  StoreTests.swift
//  Razzil
//
//  Created by jk on 2025-02-25.
//

import Testing
@testable import Razzil

struct StoreTests {
    var store: Store
    init() async throws {
        store = Store(productIds: ["id1", "id2"])
    }
    
    @Test func testInitialize() async {
        await #expect(throws: Store.SyncError.self, "unknown product id") {
            try await store.initialize()
        }
        await #expect(store.products.count == 0)
    }
}
