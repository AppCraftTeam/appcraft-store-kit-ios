import StoreKit

open class PurchaseHelper {
    public let productIdentifiers: Set<String>
    public let loadProductsRequest: LoadProductsRequest
    public let paymentProductsRequest: PaymentProductRequest
    public let receiptProductRequest: ReceiptProductRequest
    
    public init(productIdentifiers: Set<String>, sharedSecretKey: String) {
        self.productIdentifiers = productIdentifiers
        self.loadProductsRequest = .init(productIdentifiers: productIdentifiers)
        self.paymentProductsRequest = .init()
        self.receiptProductRequest = .init(sharedSecretKey: sharedSecretKey, keyReceiptMaxExpiresDate: "keyReceiptMaxExpiresDate")
    }
    
    open func checkActiveProductFromLocal(_ product: SKProduct, nowDate: Date) -> Bool {
        guard let date = self.getProductExpiresDateFromLocal(product) else { return false }
        return date > nowDate
    }
    
    open func getProductExpiresDateFromLocal(_ product: SKProduct) -> Date? {
        UserDefaults.standard.object(forKey: product.productIdentifier) as? Date
    }
    
    open func getReceiptMaxExpiresDate() -> Date? {
        UserDefaults.standard.object(forKey: self.receiptProductRequest.keyReceiptMaxExpiresDate) as? Date
    }
    
    open func purchaseAvalible() -> Bool {
        guard let date = self.getReceiptMaxExpiresDate() else { return false }
        return date > .init()
    }
}
