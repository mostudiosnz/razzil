import Gondar
import StoreKit

/**
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
 */

struct ProductOfferObject: Decodable {
//    let priceFormatted: String
    let currencyCode: String
    let price: Double
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ProductOfferObject.Keys.self)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        let priceString = try container.decode(String.self, forKey: .price)
        if let priceValue = Double(priceString) {
            price = priceValue
        } else {
            let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to cast \(priceString) to Double")
            throw DecodingError.typeMismatch(Double.self, context)
        }
    }
    
    enum Keys: String, CodingKey {
        case priceFormatted, currencyCode, price
    }
}

struct ProductObjectAttributes: Decodable {
//    let isFamilyShareable: Bool
//    let kind: String
//    let name: String
//    let offerName: String
    let offers: [ProductOfferObject]
}

struct ProductObject: Decodable {
//    let id: String
//    let href: String
//    let type: String
    let attributes: ProductObjectAttributes
}

extension Product {
    func latestOffer() throws -> ProductOfferObject? {
        try JSONDecoder().decode(ProductObject.self, from: jsonRepresentation).attributes.offers.last
    }
}

public protocol PurchaseTracking {
    var tracker: Tracker { get }
    func trackPurchaseStarted(for product: Product, in locale: Locale)
    func trackPurchaseCompleted(with transaction: Transaction)
}

public extension PurchaseTracking {
    func trackPurchaseStarted(for product: Product, in locale: Locale = .current) {
        let event: PurchaseStartedEvent
        if #available(iOS 16, *), let currency = locale.currency {
            let price = product.price
            let value = NSDecimalNumber(decimal: price).doubleValue
            let currencyId = currency.identifier
            event = PurchaseStartedEvent(currency: currencyId, value: value)
        } else {
            event = PurchaseStartedEvent()
        }
        tracker.track(event: event)
    }
    func trackPurchaseCompleted(with transaction: Transaction) {
        tracker.track(event: PurchaseCompletedEvent())
    }
}
