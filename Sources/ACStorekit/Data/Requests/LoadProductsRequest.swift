import Foundation
import StoreKit

open class LoadProductsRequest: NSObject {
    public typealias Completion = (Result<[SKProduct], Error>) -> Void
    
    private let productIdentifiers: Set<ACProductTypeItem>
    private var productsRequest: SKProductsRequest?
    private var completion: Completion?
    
    public init(productIdentifiers: Set<ACProductTypeItem>) {
        self.productIdentifiers = productIdentifiers
        super.init()
    }
    
    open func start(_ completion: Completion?) {
        productsRequest?.cancel()
        
        let identifiers = productIdentifiers.map { $0.product.productIdentifer }
        self.productsRequest = SKProductsRequest(productIdentifiers: Set(identifiers))
        self.completion = completion
        
        productsRequest?.delegate = self
        productsRequest?.start()
    }
}

extension LoadProductsRequest: SKProductsRequestDelegate {
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        finish(result: .success(response.products))
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        finish(result: .failure(error))
    }
}

private extension LoadProductsRequest {
    
    func finish(result: Result<[SKProduct], Error>) {
        completion?(result)
        completion = nil
        
        productsRequest?.cancel()
        productsRequest = nil
    }
}
