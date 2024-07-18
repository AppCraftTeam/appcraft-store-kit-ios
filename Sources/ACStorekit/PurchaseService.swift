import Foundation
import StoreKit

protocol PurchaseServiceOutput: AnyObject {
    func error(_ service: PurchaseService, error: Error?)
    func reload(_ service: PurchaseService)
    func purchase(_ service: PurchaseService)
    func restore(_ service: PurchaseService)
}

final class PurchaseService: PurchaseHelper {
    static let current = PurchaseService()
    
    weak var output: PurchaseServiceOutput?

    private(set) var products: [SKProduct] = [] {
        didSet {
            self.products.sortDefault()
            self.updateProductsActive()
        }
    }
    
    private(set) var productActive: SKProduct?
    
    private let notProvidesErrorCodes: [Int] = [2]

    init() {
        let productIdentifiers = Set(PurchaseType.allCases.compactMap({ $0.productIdentifer }))
        let sharedSecretKey = "66eb9a4cecb841d986256b6646b1e394"
        
        super.init(productIdentifiers: productIdentifiers, sharedSecretKey: sharedSecretKey)
    }

    var productActiveIndex: Int? {
        self.products.firstIndex(where: { $0.productIdentifier == self.productActive?.productIdentifier })
    }
    
    func avalibleActiveProduct() {
        
    }
    
    private func provideError(_ error: Error?) {
        if let error = error, !self.notProvidesErrorCodes.contains((error as NSError).code) {
            self.output?.error(self, error: error)
        } else {
            self.output?.error(self, error: nil)
        }
    }
    
    func updateProductsActive() {
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
    
    func loadProducts() {
        self.loadProductsRequest.start { [weak self] products, error in
            guard let self = self else { return }
            
            guard error == nil else {
                self.provideError(error)
                return
            }
            
            self.products = products
            self.output?.reload(self)
        }
    }
    
    func purchase(_ product: SKProduct) {
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

    func restore() {
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


