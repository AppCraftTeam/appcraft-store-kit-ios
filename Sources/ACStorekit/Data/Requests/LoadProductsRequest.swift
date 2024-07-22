import Foundation
import StoreKit

open class LoadProductsRequest: NSObject {
    public typealias Completion = ([SKProduct], Error?) -> Void
    
    private let productIdentifiers: Set<ACProductTypeItem>
    private var productsRequest: SKProductsRequest?
    private var completion: Completion?
    
    public init(productIdentifiers: Set<ACProductTypeItem>) {
        self.productIdentifiers = productIdentifiers
    }
    deinit {
        print("deinit LoadProductsRequest")
    }
    open func start(_ completion: Completion?) {
        self.productsRequest?.cancel()
        
        let ids = self.productIdentifiers.map({ $0.product.productIdentifer })
        self.productsRequest = .init(productIdentifiers: Set(ids))
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

    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.finish(result: response.products, error: nil)
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        self.finish(result: [], error: error)
    }
}
