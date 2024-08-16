import Foundation
import StoreKit

open class PurchaseService: PurchaseHelper {
    
    // MARK: - Callbacks
    public var didUpdateProductsList: ((Result<[ACPurchases], Error>) -> Void)?
    public var didCompletePurchase: ((Result<[ACPurchases], Error>) -> Void)?
    public var didRestorePurchases: ((Result<[ACPurchases], Error>) -> Void)?
    
    // MARK: - Params
    private(set) public var products: [ACPurchases] = [] {
        didSet {
            products.sortDefault()
            updateProductsActiveStatus()
        }
    }
    
    public static let current = PurchaseService(products: [], sharedSecretKey: "")
    public var validationType: ReceiptValidationType = .apple
    
    
    public init(products: Set<ACProductTypeItem>, sharedSecretKey: String) {
        super.init(productIdentifiers: products, sharedSecretKey: sharedSecretKey, keyReceiptMaxExpiresDate: "keyReceiptMaxExpiresDate")
    }
    
    open func setupCallbacks(
        didUpdateProductsList: ((Result<[ACPurchases], Error>) -> Void)?,
        didCompletePurchase: ((Result<[ACPurchases], Error>) -> Void)?,
        didRestorePurchases: ((Result<[ACPurchases], Error>) -> Void)?
    ) {
        self.didUpdateProductsList = didUpdateProductsList
        self.didCompletePurchase = didCompletePurchase
        self.didRestorePurchases = didRestorePurchases
    }
    
    open func updateProductsActiveStatus() {
        guard purchaseAvailable() else { return }
        products.forEach { product in
            let expiresDate = getProductExpiresDateFromLocal(product.skProduct)
            let isActive = isActiveProduct(product.skProduct)
            product.updateActive(isActive, expiresDate: expiresDate)
        }
        print("updateProductsActiveStatus productsItems - \(products.map { $0.debugDescription })")
    }
    
    open func loadProducts() {
        print("loadProducts... \(productIdentifiers)")
        loadProductsRequest.start { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(products):
                self.handleLoadedProducts(products)
            case let .failure(error):
                self.didUpdateProductsList?(.failure(error))
            }
        }
    }
    
    open func fetchReceipt(validationType: ReceiptValidationType, callback: @escaping (Result<Data, Error>) -> Void) {
        receiptProductRequest.start(validationType: validationType) { result in
            callback(result)
        }
    }
    
    open func purchase(_ product: SKProduct) {
        paymentProductsRequest.purchase(product: product) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.handlePurchaseSuccess()
            case let .failure(error):
                self.didCompletePurchase?(.failure(error))
            }
        }
    }
    
    open func restore() {
        print("restore")
        paymentProductsRequest.restore { [weak self] result in
            print("restore...")
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.handleRestoreSuccess()
            case let .failure(error):
                self.didRestorePurchases?(.failure(error))
            }
        }
    }
}

// MARK: - Private Methods

private extension PurchaseService {
    
    func handleLoadedProducts(_ products: [SKProduct]) {
        var productsItems: [ACPurchases] = []
        let arr = Array(productIdentifiers)
        
        for sdkProduct in products {
            let expiresDate = getProductExpiresDateFromLocal(sdkProduct)
            let isActive = isActiveProduct(sdkProduct)
            
            if let info = arr.getProduct(for: sdkProduct.productIdentifier) {
                productsItems.append(ACPurchases(
                    product: info,
                    skProduct: sdkProduct,
                    expiresDate: expiresDate,
                    isActive: isActive
                ))
            }
        }
        
        self.products = productsItems
        print("products productsItems - \(productsItems.map { $0.debugDescription })")
        didUpdateProductsList?(.success(self.products))
    }
    
    func handlePurchaseSuccess() {
        fetchReceipt(validationType: validationType) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(receipt):
                self.updateProductsActiveStatus()
                self.didCompletePurchase?(.success(self.products.getActiveProducts()))
                self.didUpdateProductsList?(.success(self.products))
            case let .failure(error):
                self.didCompletePurchase?(.failure(error))
            }
        }
    }
    
    func handleRestoreSuccess() {
        fetchReceipt(validationType: validationType) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(receipt):
                self.updateProductsActiveStatus()
                self.didRestorePurchases?(.success(self.products))
                self.didUpdateProductsList?(.success(self.products))
            case let .failure(error):
                self.didRestorePurchases?(.failure(error))
            }
        }
    }
    
    func isActiveProduct(_ product: SKProduct) -> Bool {
        let nowDate = Date()
        guard
            isActiveProductExpiresDateFromLocal(product, nowDate: nowDate),
            let expiresDate = getProductExpiresDateFromLocal(product),
            expiresDate > nowDate
        else {
            return false
        }
        return true
    }
}
