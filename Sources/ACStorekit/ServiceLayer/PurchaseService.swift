import Foundation
import StoreKit

public enum PurchaseAction {
    case purchase, restore
}

open class PurchaseService: PurchaseHelper {
    
    // MARK: - Callbacks
    public var didProductsListUpdated: ((_: [ACPurchases]) -> Void)?
    public var didProductPurchased: ((_: [ACPurchases]) -> Void)?
    public var didProductsRestored: ((_: [ACPurchases]) -> Void)?
    public var didFailedFetchProducts: ((_: Error?) -> Void)?
    public var didFailedBuyPurchase: ((_: Error?) -> Void)?
    public var didFailedRestorePurchase: ((_: Error?) -> Void)?
    
    // MARK: - Params
    private(set) public var products: [ACPurchases] = [] {
        didSet {
            self.products.sortDefault()
            self.updateProductsActiveStatus()
        }
    }
    
    private var currentAction: PurchaseAction?
        
    // paymentCancelled
    private let notProvidesErrorCodes: [Int] = [2]
    
    public static let current = PurchaseService(products: [], sharedSecretKey: "")
    public var validationType: ReceiptValidationType = .manual
    
    public init(products: Set<ACProductTypeItem>, sharedSecretKey: String) {
        super.init(productIdentifiers: products, sharedSecretKey: sharedSecretKey, keyReceiptMaxExpiresDate: "keyReceiptMaxExpiresDate")
    }
    
    deinit {
        print("deinit PurchaseService")
    }
    
    func makeErrorObjectify(_ error: Error?) -> Error? {
        if let error = error,
           !self.notProvidesErrorCodes.contains((error as NSError).code) {
            return error
        }
        return nil
    }
    
    open func setupCallbacks(
        didProductsListUpdated: ((_: [ACPurchases]) -> Void)?,
        didProductPurchased: ((_: [ACPurchases]) -> Void)?,
        didProductsRestored: ((_: [ACPurchases]) -> Void)?,
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
    
    open func updateProductsActiveStatus() {
        guard self.purchaseAvalible() else { return }
        self.products.forEach({ product in
            let expiresDate: Date? = self.getProductExpiresDateFromLocal(product.skProduct)
            let isActive = self.isActiveProduct(product.skProduct)
            
            product.updateActive(isActive, expiresDate: expiresDate)
        })
        print("updateProductsActiveStatus productsItems - \(products.map({ $0.debugDescription }))")
    }
    
    open func loadProducts() {
        print("loadProducts... \(self.productIdentifiers)")
        self.loadProductsRequest.start { [weak self] products, error in
            guard let self = self else { return }
            
            guard error == nil else {
                self.didFailedFetchProducts?(self.makeErrorObjectify(error))
                return
            }
            var productsItems: [ACPurchases] = []
            let arr = Array(self.productIdentifiers)
            
            products.forEach({ sdkProduct in
                let expiresDate: Date? = self.getProductExpiresDateFromLocal(sdkProduct)
                let isActive = self.isActiveProduct(sdkProduct)
                
                if let info = arr.getProduct(for: sdkProduct.productIdentifier) {
                    productsItems += [
                        ACPurchases(
                            product: info,
                            skProduct: sdkProduct,
                            expiresDate: expiresDate,
                            isActive: isActive
                        )
                    ]
                }
            })
            
            self.products = productsItems
            print("products productsItems - \(productsItems.map({ $0.debugDescription }))")
            self.didProductsListUpdated?(self.products)
        }
    }
    
    private func isActiveProduct(_ product: SKProduct) -> Bool {
        let date = Date()
        var productDate = Date()
        let expiresDate: Date? = self.getProductExpiresDateFromLocal(product)

        guard
            self.isActiveProductExpiresDateFromLocal(product, nowDate: date),
            let expiresDate = expiresDate,
            expiresDate > productDate
        else {
            return false
        }
        return true
    }
    
    open func fetchReceipt(validationType: ReceiptValidationType, callback: @escaping (Result<Data?, Error>) -> Void) {
        self.receiptProductRequest.start(validationType: validationType) { [weak self] data, error in
            guard let self = self else { return }
            if let error = error {
                callback(.failure(error))
                return
            }
            
            callback(.success((data.receipt)))
        }
    }
    
    open func purchase(_ product: SKProduct) {
        self.paymentProductsRequest.puschase(product: product) { [weak self] _, error in
            guard let self = self else { return }
            
            guard error == nil else {
                self.didFailedBuyPurchase?(self.makeErrorObjectify(error))
                return
            }
            
            self.fetchReceipt(validationType: self.validationType) { result in
                switch result {
                case let .success(receipt):
                    self.updateProductsActiveStatus()
                    self.didProductPurchased?(self.products.getActiveProducts())
                    self.didProductsListUpdated?(self.products)
                case let .failure(error):
                    self.didFailedFetchProducts?(self.makeErrorObjectify(error))
                }
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
            
            self.fetchReceipt(validationType: self.validationType) { result in
                switch result {
                case let .success(receipt):
                    self.updateProductsActiveStatus()
                    self.didProductsRestored?(self.products)
                    self.didProductsListUpdated?(self.products)
                case let .failure(error):
                    self.didFailedFetchProducts?(self.makeErrorObjectify(error))
                }
            }
        }
    }
}


