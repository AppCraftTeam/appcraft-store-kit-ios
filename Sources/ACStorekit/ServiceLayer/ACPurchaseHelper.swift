import StoreKit

open class ACPurchaseHelper {
    private let keyReceiptMaxExpiresDate: String

    public let productIdentifiers: Set<ACProductTypeItem>
    public let ACLoadProductsRequest: ACLoadProductsRequest
    public let paymentProductsRequest: ACPaymentProductRequest
    public let ACReceiptProductRequest: ACReceiptProductRequest
    
    public init(productIdentifiers: Set<ACProductTypeItem>, sharedSecretKey: String, keyReceiptMaxExpiresDate: String) {
        self.productIdentifiers = productIdentifiers
        self.ACLoadProductsRequest = .init(productIdentifiers: productIdentifiers)
        self.paymentProductsRequest = .init()
        self.ACReceiptProductRequest = .init(sharedSecretKey: sharedSecretKey, keyReceiptMaxExpiresDate: keyReceiptMaxExpiresDate)
        self.keyReceiptMaxExpiresDate = keyReceiptMaxExpiresDate
    }
    
    open func getReceiptMaxExpiresDate() -> Date? {
        UserDefaults.standard.object(forKey: self.keyReceiptMaxExpiresDate) as? Date
    }
    
    open func purchaseAvailable() -> Bool {
        guard let date = self.getReceiptMaxExpiresDate() else { return false }
        return date > .init()
    }
}
