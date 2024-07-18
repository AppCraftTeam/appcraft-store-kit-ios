import Foundation
import StoreKit

class LoadProductsRequest: NSObject {
    typealias Completion = ([SKProduct], Error?) -> Void
    
    private let productIdentifiers: Set<String>
    private var productsRequest: SKProductsRequest?
    private var completion: Completion?
    
    init(productIdentifiers: Set<String>) {
        self.productIdentifiers = productIdentifiers
    }
    
    func start(_ completion: Completion?) {
        self.productsRequest?.cancel()
        
        self.productsRequest = .init(productIdentifiers: self.productIdentifiers)
        self.completion = completion
        
        self.productsRequest?.delegate = self
        self.productsRequest?.start()
    }
    
    private func finish(result: [SKProduct], error: Error?) {
        self.completion?(result, error)
        self.completion = nil
        
        self.productsRequest?.cancel()
        self.productsRequest = nil
    }
}

extension LoadProductsRequest: SKProductsRequestDelegate {

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.finish(result: response.products, error: nil)
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.finish(result: [], error: error)
    }
    
}
