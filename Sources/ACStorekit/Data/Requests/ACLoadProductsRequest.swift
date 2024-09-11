import Foundation
import StoreKit

/// `ACLoadProductsRequest` handles fetching products from the App Store
open class ACLoadProductsRequest: NSObject {
    
    /// Typealias for the completion handler
    public typealias Completion = (Result<[SKProduct], Error>) -> Void
    
    /// A set of `ACProductTypeItem` which holds the product identifiers for loading
    private let productIdentifiers: Set<ACProductTypeItem>
    
    /// The `SKProductsRequest` instance used to query the App Store for product information
    private var productsRequest: SKProductsRequest?
    
    /// The completion handler that will be invoked when the product request is finished
    private var completion: Completion?
    
    /// Initializes the request
    /// - Parameters:
    ///   - productIdentifiers: A set of `ACProductTypeItem` which contains the product identifiers to load from the App Store
    public init(productIdentifiers: Set<ACProductTypeItem>) {
        self.productIdentifiers = productIdentifiers
        super.init()
    }
    
    /// Starts the product request to load products
    /// - Parameters:
    ///   - completion: A completion handler that returns the result of the product request
    open func start(_ completion: Completion?) {
        // Cancel any ongoing request before starting a new one.
        productsRequest?.cancel()
        
        // Extract the product identifiers
        let identifiers = productIdentifiers.map { $0.product.productIdentifer }
        
        // Create and initialize the `SKProductsRequest`
        self.productsRequest = SKProductsRequest(productIdentifiers: Set(identifiers))
        self.completion = completion
        
        // Set the delegate and start the request.
        productsRequest?.delegate = self
        productsRequest?.start()
    }
}

// MARK: - SKProductsRequestDelegate
extension ACLoadProductsRequest: SKProductsRequestDelegate {
    
    /// Called when the product request successfully retrieves products from the App Store
    ///   - response: The `SKProductsResponse` containing the available products
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        finish(result: .success(response.products))
    }
    
    /// Called when the request fails to load products due to an error
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        finish(result: .failure(error))
    }
}

private extension ACLoadProductsRequest {
    
    /// Finish the reques
    func finish(result: Result<[SKProduct], Error>) {
        completion?(result)
        
        // Cancel and clear the `productsRequest` to clean up
        productsRequest?.cancel()
        productsRequest = nil
    }
}
