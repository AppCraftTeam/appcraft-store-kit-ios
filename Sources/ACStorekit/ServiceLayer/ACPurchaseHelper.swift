import StoreKit

open class ACPurchaseHelper {
    /// Key to max expiration date of receipts
    private let keyReceiptMaxExpiresDate: String
    
    /// Product identifiers
    public let productIdentifiers: Set<ACProductTypeItem>
    
    /// Handles product information fetching from the App Store
    public let loadProductsRequest: ACLoadProductsRequest
    
    /// Handles purchasing and restoring transactions
    public let paymentProductsRequest: ACPaymentProductRequest
    
    /// Manages receipt validation and expiration checking
    public let receiptProductRequest: ACReceiptProductRequest
    
    /// DLog level to control verbosity of the logging
    public var logLevel: ACLogLevel
    
    /// Initializes the `ACPurchaseHelper`
    /// - Parameters:
    ///   - productIdentifiers: Product identifiers
    ///   - sharedSecretKey: The shared secret key used for validating receipts with Apple
    ///   - keyReceiptMaxExpiresDate: Key to max expiration date of receipts
    ///   - logLevel: Log level to control verbosity of the logging
    public init(productIdentifiers: Set<ACProductTypeItem>, sharedSecretKey: String, keyReceiptMaxExpiresDate: String, logLevel: ACLogLevel) {
        self.productIdentifiers = productIdentifiers
        self.logLevel = logLevel
        self.loadProductsRequest = .init(productIdentifiers: productIdentifiers)
        self.paymentProductsRequest = .init()
        self.receiptProductRequest = .init(sharedSecretKey: sharedSecretKey, keyReceiptMaxExpiresDate: keyReceiptMaxExpiresDate, logLevel: logLevel)
        self.keyReceiptMaxExpiresDate = keyReceiptMaxExpiresDate
    }
    
    /// Retrieves the maximum receipt expiration date from UserDefaults
    open func getReceiptMaxExpiresDate() -> Date? {
        UserDefaults.standard.object(forKey: self.keyReceiptMaxExpiresDate) as? Date
    }
    
    /// Checks if any purchase is still valid based on the expiration date
    open func purchaseAvailable() -> Bool {
        guard let date = self.getReceiptMaxExpiresDate() else { return false }
        return date > .init()
    }
}
