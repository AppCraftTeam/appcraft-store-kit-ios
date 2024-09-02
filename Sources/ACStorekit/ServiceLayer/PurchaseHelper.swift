import StoreKit

open class PurchaseHelper {
    private let keyReceiptMaxExpiresDate: String

    public let productIdentifiers: Set<ACProductTypeItem>
    public let loadProductsRequest: LoadProductsRequest
    public let paymentProductsRequest: PaymentProductRequest
    public let receiptProductRequest: ReceiptProductRequest
    
    public init(productIdentifiers: Set<ACProductTypeItem>, sharedSecretKey: String, keyReceiptMaxExpiresDate: String) {
        self.productIdentifiers = productIdentifiers
        self.loadProductsRequest = .init(productIdentifiers: productIdentifiers)
        self.paymentProductsRequest = .init()
        self.receiptProductRequest = .init(sharedSecretKey: sharedSecretKey, keyReceiptMaxExpiresDate: keyReceiptMaxExpiresDate)
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
