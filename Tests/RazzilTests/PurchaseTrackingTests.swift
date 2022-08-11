//
//  PurchaseTrackingTests.swift
//  
//
//  Created by jk on 2022-08-11.
//

import XCTest
@testable import Razzil

class PurchaseTrackingTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testProductObjectDecoding() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        let jsonString = """
         {
             "attributes": {
                 "description": {
                     "standard": ""
                 },
                 "isFamilyShareable": 0,
                 "kind": "Non-Consumable",
                 "name": "",
                 "offerName": "ES.NC1",
                 "offers": [
                     {
                         "currencyCode": "USD",
                         "price": "5.99",
                         "priceFormatted": "$5.99"
                     }
                 ]
             },
             "href": "/v1/catalog/usa/in-apps/5E90DBD0",
             "id": "5E90DBD0",
             "type": "in-apps"
         }
        """
        let data = jsonString.data(using: .utf8)!
        let obj = try! JSONDecoder().decode(ProductObject.self, from: data)
        XCTAssertEqual(obj.attributes.offers[0].currencyCode, "USD")
        XCTAssertEqual(obj.attributes.offers[0].price, 5.99)
    }
}
