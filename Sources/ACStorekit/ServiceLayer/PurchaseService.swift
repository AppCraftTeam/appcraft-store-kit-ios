import Foundation
import StoreKit

public enum PurchaseAction {
    case purchase, restore
}

open class PurchaseService: PurchaseHelper {

    // MARK: - Callbacks
    public var didProductsListUpdated: ((_: [ACPurchases]) -> Void)?
    public var didProductPurchased: ((_: ACPurchases) -> Void)?
    public var didProductsRestored: ((_: ACPurchases) -> Void)?
    public var didFailedFetchProducts: ((_: Error?) -> Void)?
    public var didFailedBuyPurchase: ((_: Error?) -> Void)?
    public var didFailedRestorePurchase: ((_: Error?) -> Void)?

    // MARK: - Params
    private(set) public var products: [ACPurchases] = [] {
        didSet {
            self.products.sortDefault()
            self.updateProductsActive()
        }
    }
    
    private var currentAction: PurchaseAction?
    
    private(set) public var productActive: SKProduct?
    
    // paymentCancelled
    private let notProvidesErrorCodes: [Int] = [2]

    public static let current = PurchaseService(sharedSecretKey: "", products: [])

    public init(sharedSecretKey: String, products: Set<ACProductTypeItem>) {
        super.init(productIdentifiers: products, sharedSecretKey: sharedSecretKey)
    }
    
    deinit {
        print("deinit PurchaseService")
    }
    
    open var productActiveIndex: Int? {
        self.products.firstIndex(where: { $0.product.productIdentifer == self.productActive?.productIdentifier })
    }
    
    open func avalibleActiveProduct() {}
    
    func makeErrorObjectify(_ error: Error?) -> Error? {
        if let error = error,
           !self.notProvidesErrorCodes.contains((error as NSError).code) {
            return error
        }
        return nil
    }
    
    open func setupCallbacks(
        didProductsListUpdated: ((_: [ACPurchases]) -> Void)?,
        didProductPurchased: ((_: ACPurchases) -> Void)?,
        didProductsRestored: ((_: ACPurchases) -> Void)?,
        didFailedFetchProducts: ((_: Error?) -> Void)?,
        didFailedBuyPurchase: ((_: Error?) -> Void)?,
        didFailedRestorePurchase: ((_: Error?) -> Void)?
    ) {
        self.didProductsListUpdated = didProductsListUpdated
        self.didProductPurchased = didProductPurchased
        self.didProductsRestored = didProductsRestored
        self.didFailedFetchProducts = didFailedFetchProducts
        self.didFailedBuyPurchase = didFailedBuyPurchase
        self.didFailedRestorePurchase = didFailedRestorePurchase
    }
    
    open func updateProductsActive() {
        let date = Date()
        var productDate = Date()
        
        self.productActive = nil
        guard self.purchaseAvalible() else { return }
        
        for product in self.products.map({ $0.skProduct }) {
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
        print("loadProducts... \(self.productIdentifiers)")
        self.loadProductsRequest.start { [weak self] products, error in
            print("products - \(products), error - \(error)")
            guard let self = self else { return }
            
            guard error == nil else {
                self.didFailedFetchProducts?(self.makeErrorObjectify(error))
                return
            }
            var productsItems: [ACPurchases] = []
            let arr = Array(self.productIdentifiers)
            products.forEach({ sdkProduct in
                print("products vvvv - \(arr.getProduct(for: sdkProduct.productIdentifier))")

                if let info = arr.getProduct(for: sdkProduct.productIdentifier) {
                    productsItems += [
                        ACPurchases(
                            product: info,
                            skProduct: sdkProduct
                        )
                    ]
                }
            })
            print("products arr - \(arr)")

            self.products = productsItems
            print("products productsItems - \(productsItems) is \(productsItems.map({ $0.skProduct.productIdentifier }))")
            self.didProductsListUpdated?(self.products)
        }
    }
    
    open func purchase(_ product: SKProduct) {
        self.paymentProductsRequest.puschase(product: product) { [weak self] _, error in
            guard let self = self else { return }
            
            guard error == nil else {
                self.didFailedBuyPurchase?(self.makeErrorObjectify(error))
                return
            }
            
            self.receiptProductRequest.start { [weak self] _, error in
                guard let self = self else { return }
                
                guard error == nil else {
                    self.didFailedFetchProducts?(self.makeErrorObjectify(error))
                    return
                }
                
                self.updateProductsActive()
                //self.didProductPurchased?()
                self.didProductsListUpdated?(self.products)
            }
        }
    }

    open func restore() {
        print("restore")
        self.paymentProductsRequest.restore { [weak self] _, error in
            print("restore...")
            guard let self = self else { return }
            
            guard error == nil else {
                self.didFailedRestorePurchase?(self.makeErrorObjectify(error))
                return
            }
            
            self.receiptProductRequest.start { [weak self] _, error in
                guard let self = self else { return }
                
                guard error == nil else {
                    self.didFailedRestorePurchase?(self.makeErrorObjectify(error))
                    return
                }
                
                self.updateProductsActive()
                //self.didProductsRestored?()
                self.didProductsListUpdated?(self.products)
            }
        }
    }
}


