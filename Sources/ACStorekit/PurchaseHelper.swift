import StoreKit

class PurchaseHelper {
    let productIdentifiers: Set<String>
    let loadProductsRequest: LoadProductsRequest
    let paymentProductsRequest: PaymentProductRequest
    let receiptProductRequest: ReceiptProductRequest
    
    init(productIdentifiers: Set<String>, sharedSecretKey: String) {
        self.productIdentifiers = productIdentifiers
        self.loadProductsRequest = .init(productIdentifiers: productIdentifiers)
        self.paymentProductsRequest = .init()
        self.receiptProductRequest = .init(sharedSecretKey: sharedSecretKey, keyReceiptMaxExpiresDate: "keyReceiptMaxExpiresDate")
    }
    
    func checkActiveProductFromLocal(_ product: SKProduct, nowDate: Date) -> Bool {
        guard let date = self.getProductExpiresDateFromLocal(product) else { return false }
        return date > nowDate
    }
    
    func getProductExpiresDateFromLocal(_ product: SKProduct) -> Date? {
        UserDefaults.standard.object(forKey: product.productIdentifier) as? Date
    }
    
    func getReceiptMaxExpiresDate() -> Date? {
        UserDefaults.standard.object(forKey: self.receiptProductRequest.keyReceiptMaxExpiresDate) as? Date
    }
    
    func purchaseAvalible() -> Bool {
        guard let date = self.getReceiptMaxExpiresDate() else { return false }
        return date > .init()
    }
    
}
