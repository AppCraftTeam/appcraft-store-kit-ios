import Foundation
import StoreKit

open class ACPurchaseService: ACPurchaseHelper {
    
    // MARK: - Callbacks
    public var didUpdateProductsList: ((Result<[ACPurchases], Error>) -> Void)?
    public var didCompletePurchase: ((Result<[ACPurchases], Error>) -> Void)?
    public var didRestorePurchases: ((Result<[ACPurchases], Error>) -> Void)?
    
    // MARK: - Params
    private(set) public var products: [ACPurchases] = [] {
        didSet {
            products.sortDefault()
        }
    }
    
    public static let current = ACPurchaseService(products: [], sharedSecretKey: "")
    public var validationType: ACReceiptValidationType = .apple
    
    
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

    open func loadProducts() {
        print("loadProducts... \(productIdentifiers)")
        ACLoadProductsRequest.start { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(products):
                self.handleLoadedProducts(products)
            case let .failure(error):
                self.didUpdateProductsList?(.failure(error))
            }
        }
    }
    
    open func fetchReceipt(validationType: ACReceiptValidationType, callback: @escaping (Result<ACReceiptProductInfo, Error>) -> Void) {
        ACReceiptProductRequest.start(validationType: validationType) { result in
            print("fetchReceipt result result - \(result)")
            switch result {
            case let .success(data):
                data.expiredInfo.forEach({ info in
                    self.products
                        .first(where: { $0.product.productIdentifer == info.productId })?
                        .saveExpiresDate(info.date)
                })
            case .failure:
                break
            }
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

private extension ACPurchaseService {
    
    func handleLoadedProducts(_ products: [SKProduct]) {
        var productsItems: [ACPurchases] = []
        let arr = Array(productIdentifiers)
        
        for sdkProduct in products {
            if let info = arr.getProduct(for: sdkProduct.productIdentifier) {
                productsItems += [
                    ACPurchases(
                        product: info,
                        skProduct: sdkProduct
                    )
                ]
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
                self.didCompletePurchase?(.success(self.products.getActiveProducts()))
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
                self.didRestorePurchases?(.success(self.products))
            case let .failure(error):
                self.didRestorePurchases?(.failure(error))
            }
        }
    }
}
