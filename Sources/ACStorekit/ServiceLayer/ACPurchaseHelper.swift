import StoreKit

open class ACPurchaseHelper {
    private let keyReceiptMaxExpiresDate: String

    public let productIdentifiers: Set<ACProductTypeItem>
    public let loadProductsRequest: ACLoadProductsRequest
    public let paymentProductsRequest: ACPaymentProductRequest
    public let receiptProductRequest: ACReceiptProductRequest
    public var logLevel: ACLogLevel

    public init(productIdentifiers: Set<ACProductTypeItem>, sharedSecretKey: String, keyReceiptMaxExpiresDate: String, logLevel: ACLogLevel) {
        self.productIdentifiers = productIdentifiers
        self.logLevel = logLevel
        self.loadProductsRequest = .init(productIdentifiers: productIdentifiers)
        self.paymentProductsRequest = .init()
        self.receiptProductRequest = .init(sharedSecretKey: sharedSecretKey, keyReceiptMaxExpiresDate: keyReceiptMaxExpiresDate, logLevel: logLevel)
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
