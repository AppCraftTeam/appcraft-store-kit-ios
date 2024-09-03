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
    
    public var validationType: ACReceiptValidationType = .apple
    
    public init(products: Set<ACProductTypeItem>, sharedSecretKey: String, logLevel: ACLogLevel) {
        super.init(productIdentifiers: products, sharedSecretKey: sharedSecretKey, keyReceiptMaxExpiresDate: "keyReceiptMaxExpiresDate", logLevel: logLevel)
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
        if logLevel == .full {
            print("[ACPurchaseService] loadProducts started, productIdentifiers: \(productIdentifiers)")
        }
        loadProductsRequest.start { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(products):
                if logLevel == .full {
                    print("[ACPurchaseService] loadProducts, products: \(products)")
                }
                self.handleLoadedProducts(products)
            case let .failure(error):
                if self.logLevel.isAllowPrintError {
                    print("[ACPurchaseService] loadProducts, error: \(error)")
                }
                self.didUpdateProductsList?(.failure(error))
            }
        }
    }
    
    open func fetchReceipt(validationType: ACReceiptValidationType, callback: @escaping (Result<ACReceiptProductInfo, Error>) -> Void) {
        if logLevel == .full {
            print("[ACPurchaseService] fetchReceipt started, validationType: \(validationType)")
        }
        receiptProductRequest.start(validationType: validationType) { result in
            switch result {
            case let .success(data):
                if self.logLevel == .full {
                    print("[ACPurchaseService] fetchReceipt, data: \(data)")
                }
                data.expiredInfo.forEach({ info in
                    self.products
                        .first(where: { $0.product.productIdentifer == info.productId })?
                        .saveExpiresDate(info.date)
                })
            case let .failure(error):
                if self.logLevel.isAllowPrintError {
                    print("[ACPurchaseService] fetchReceipt, error: \(error)")
                }
            }
            callback(result)
        }
    }
    
    open func purchase(_ product: SKProduct) {
        if logLevel == .full {
            print("[ACPurchaseService] Purchase \(product) started")
        }
        paymentProductsRequest.purchase(product: product) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                if self.logLevel == .full {
                    print("[ACPurchaseService] purchase product \(product) successed")
                }
                self.handlePurchaseSuccess()
            case let .failure(error):
                if self.logLevel.isAllowPrintError {
                    print("[ACPurchaseService] purchase product \(product) failed, error: \(error)")
                }
                self.didCompletePurchase?(.failure(error))
            }
        }
    }
    
    open func restore() {
        if logLevel == .full {
            print("[ACPurchaseService] Restore started")
        }
        paymentProductsRequest.restore { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                if self.logLevel == .full {
                    print("[ACPurchaseService] restore product successed")
                }
                self.handleRestoreSuccess()
            case let .failure(error):
                if self.logLevel.isAllowPrintError {
                    print("[ACPurchaseService] restore failed, error: \(error)")
                }
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
        if self.logLevel == .full {
            print("[ACPurchaseService] products: \(productsItems.map { $0.debugDescription })")
        }
        didUpdateProductsList?(.success(self.products))
    }
    
    func handlePurchaseSuccess() {
        if self.logLevel == .full {
            print("[ACPurchaseService] purchase successed, starting fetch request")
        }
        fetchReceipt(validationType: validationType) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(receipt):
                if self.logLevel == .full {
                    print("[ACPurchaseService] fetch receipt after payment successed")
                }
                self.didCompletePurchase?(.success(self.products.getActiveProducts()))
            case let .failure(error):
                if self.logLevel.isAllowPrintError {
                    print("[ACPurchaseService] fetch receipt after purchased failed, error: \(error)")
                }
                self.didCompletePurchase?(.failure(error))
            }
        }
    }
    
    func handleRestoreSuccess() {
        if self.logLevel == .full {
            print("[ACPurchaseService] restore successed, starting fetch request")
        }
        fetchReceipt(validationType: validationType) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(receipt):
                if self.logLevel == .full {
                    print("[ACPurchaseService] fetch receipt after restored successed")
                }
                self.didRestorePurchases?(.success(self.products))
            case let .failure(error):
                if self.logLevel.isAllowPrintError {
                    print("[ACPurchaseService] fetch receipt after restored failed, error: \(error)")
                }
                self.didRestorePurchases?(.failure(error))
            }
        }
    }
}
