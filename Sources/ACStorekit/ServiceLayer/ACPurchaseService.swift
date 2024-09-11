import Foundation
import StoreKit

/// Managing in-app purchases, loading products, handling purchases, validating receipts, restoring purchases.
open class ACPurchaseService: ACPurchaseHelper {
    
    // MARK: - Callbacks
    
    /// A callback that triggers when the product list is updated, with either the products or an error.
    public var didUpdateProductsList: ((Result<[ACPurchases], Error>) -> Void)?
    
    /// A callback that triggers when a purchase is completed successfully or fails.
    public var didCompletePurchase: ((Result<[ACPurchases], Error>) -> Void)?
    
    /// A callback that triggers when the restoration of previous purchases completes successfully or fails.
    public var didRestorePurchases: ((Result<[ACPurchases], Error>) -> Void)?
    
    // MARK: - Params
    
    /// The list of products currently being managed by the service.
    /// Automatically sorts products when set.
    private(set) public var products: [ACPurchases] = [] {
        didSet {
            products.sortDefault() // Sorts products by default criteria.
        }
    }
    
    /// The type of receipt validation
    public var validationType: ACReceiptValidationType = .apple
    
    /// Initializes the `ACPurchaseService` with the product identifiers, shared secret key, and log level
    /// - Parameters:
    ///   - products: A set of product identifiers managed by the service
    ///   - sharedSecretKey: The shared secret key for receipt validation
    ///   - logLevel: The log level controlling the verbosity of logs
    public init(products: Set<ACProductTypeItem>, sharedSecretKey: String, logLevel: ACLogLevel) {
        super.init(productIdentifiers: products, sharedSecretKey: sharedSecretKey, keyReceiptMaxExpiresDate: "keyReceiptMaxExpiresDate", logLevel: logLevel)
    }
    
    /// Sets up the callbacks for product list updates, purchase completions, and restored purchases.
    /// - Parameters:
    ///   - didUpdateProductsList: A callback for when the product list is updated
    ///   - didCompletePurchase: A callback for when a purchase is completed
    ///   - didRestorePurchases: A callback for when purchases are restored
    open func setupCallbacks(
        didUpdateProductsList: ((Result<[ACPurchases], Error>) -> Void)?,
        didCompletePurchase: ((Result<[ACPurchases], Error>) -> Void)?,
        didRestorePurchases: ((Result<[ACPurchases], Error>) -> Void)?
    ) {
        self.didUpdateProductsList = didUpdateProductsList
        self.didCompletePurchase = didCompletePurchase
        self.didRestorePurchases = didRestorePurchases
    }
    
    /// Starts the process of loading available products from the App Store.
    /// The result is passed to the `didUpdateProductsList` callback.
    open func loadProducts() {
        if logLevel == .full {
            print("[ACPurchaseService] loadProducts started, productIdentifiers: \(productIdentifiers)")
        }
        
        // Initiates the product load request.
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
    
    /// Fetches and validates the receipt using the specified validation type
    /// - Parameters:
    ///   - validationType: The type of validation to use
    ///   - callback: A callback that returns the receipt validation result or an error
    open func fetchReceipt(validationType: ACReceiptValidationType, callback: @escaping (Result<ACReceiptProductInfo, Error>) -> Void) {
        if logLevel == .full {
            print("[ACPurchaseService] fetchReceipt started, validationType: \(validationType)")
        }
        
        // Initiates the receipt fetch request
        receiptProductRequest.start(validationType: validationType) { result in
            switch result {
            case let .success(data):
                if self.logLevel == .full {
                    print("[ACPurchaseService] fetchReceipt, data: \(data)")
                }
                
                // Update product expiration dates based on the receipt information
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
    
    /// Initiates the purchase of the specified product
    /// - Parameter product: The `SKProduct` to be purchased
    open func purchase(_ product: SKProduct) {
        if logLevel == .full {
            print("[ACPurchaseService] Purchase \(product) started")
        }
        
        // Initiates the purchase request.
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
    
    /// Restores previously purchased products.
    open func restore() {
        if logLevel == .full {
            print("[ACPurchaseService] Restore started")
        }
        
        // Initiates the restore request
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
    
    /// Processes the loaded products from the App Store and updates the internal product list.
    /// - Parameter products: An array of `SKProduct` objects loaded from the App Store.
    func handleLoadedProducts(_ products: [SKProduct]) {
        var productsItems: [ACPurchases] = []
        let arr = Array(productIdentifiers) // Convert Set to Array for easier lookup.
        
        // Convert `SKProduct` objects to internal `ACPurchases` model.
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
        
        // Update the product list and trigger the callback.
        self.products = productsItems
        if self.logLevel == .full {
            print("[ACPurchaseService] products: \(productsItems.map { $0.debugDescription })")
        }
        didUpdateProductsList?(.success(self.products))
    }
    
    /// Handles successful purchase
    func handlePurchaseSuccess() {
        if self.logLevel == .full {
            print("[ACPurchaseService] purchase successed, starting fetch request")
        }
        
        // Fetch and validate the receipt after a successful purchase
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
    
    /// Handles the successful restoration of purchases
    func handleRestoreSuccess() {
        if self.logLevel == .full {
            print("[ACPurchaseService] restore successed, starting fetch request")
        }
        
        // Fetch and validate the receipt after restoring purchases.
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
