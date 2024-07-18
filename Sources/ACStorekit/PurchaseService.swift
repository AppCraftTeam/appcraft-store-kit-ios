import Foundation
import StoreKit

public protocol PurchaseServiceOutput: AnyObject {
    func error(_ service: PurchaseService, error: Error?)
    func reload(_ service: PurchaseService)
    func purchase(_ service: PurchaseService)
    func restore(_ service: PurchaseService)
}

open class PurchaseService: PurchaseHelper {
    public static let current = PurchaseService(sharedSecretKey: "")
    
    open weak var output: PurchaseServiceOutput?

    private(set) var products: [SKProduct] = [] {
        didSet {
            self.products.sortDefault()
            self.updateProductsActive()
        }
    }
    
    private(set) var productActive: SKProduct?
    
    private let notProvidesErrorCodes: [Int] = [2]

    public init(sharedSecretKey: String) {
        let productIdentifiers = Set(PurchaseType.allCases.compactMap({ $0.productIdentifer }))
        super.init(productIdentifiers: productIdentifiers, sharedSecretKey: sharedSecretKey)
    }

    open var productActiveIndex: Int? {
        self.products.firstIndex(where: { $0.productIdentifier == self.productActive?.productIdentifier })
    }
    
    open func avalibleActiveProduct() {
        
    }
    
    private func provideError(_ error: Error?) {
        if let error = error, !self.notProvidesErrorCodes.contains((error as NSError).code) {
            self.output?.error(self, error: error)
        } else {
            self.output?.error(self, error: nil)
        }
    }
    
    open func updateProductsActive() {
        let date = Date()
        var productDate = Date()
        
        self.productActive = nil
        guard self.purchaseAvalible() else { return }
        
        for product in self.products {
            guard
                self.checkActiveProductFromLocal(product, nowDate: date),
                let expiresDate = self.getProductExpiresDateFromLocal(product),
                expiresDate > productDate
            else { continue }
            
            self.productActive = product
            productDate = expiresDate
        }
    }
    
    open func loadProducts() {
        print("loadProducts...")
        self.loadProductsRequest.start { [weak self] products, error in
            print("products - \(products), error - \(error)")
            guard let self = self else { return }
            
            guard error == nil else {
                self.provideError(error)
                return
            }
            
            self.products = products
            self.output?.reload(self)
        }
    }
    
    open func purchase(_ product: SKProduct) {
        self.paymentProductsRequest.puschase(product: product) { [weak self] _, error in
            guard let self = self else { return }
            
            guard error == nil else {
                self.provideError(error)
                return
            }
            
            self.receiptProductRequest.start { [weak self] _, error in
                guard let self = self else { return }
                
                guard error == nil else {
                    self.provideError(error)
                    return
                }
                
                self.updateProductsActive()
                self.output?.purchase(self)
            }
        }
    }

    open func restore() {
        self.paymentProductsRequest.restore { [weak self] _, error in
            guard let self = self else { return }
            
            guard error == nil else {
                self.provideError(error)
                return
            }
            
            self.receiptProductRequest.start { [weak self] _, error in
                guard let self = self else { return }
                
                guard error == nil else {
                    self.provideError(error)
                    return
                }
                
                self.updateProductsActive()
                self.output?.restore(self)
            }
        }
    }
}


