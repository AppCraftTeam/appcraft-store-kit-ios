//
//  SubscriptionsViewModel.swift
//  ACStorekitDemo
//
//  Created by Pavel Moslienko on 18.07.2024.
//

import ACStorekit
import Foundation

final class SubscriptionsViewModel {
    
    // MARK: - Params
    var purchaseService: PurchaseService
    var remoteService: MockupRemoteService
    
    var selectedProduct: ACPurchases?
    
    // MARK: - Callbacks
    var didProductsLoaded: (() -> Void)?
    var didBeginLoading: (() -> Void)?
    var didStopLoading: (() -> Void)?
    
    private static var products: Set<ACProductTypeItem> {
        Set(AppPurchases.allCases.map({ ACProductTypeItem(product: $0.product) }))
    }
    
    init() {
        self.purchaseService = PurchaseService(products: SubscriptionsViewModel.products, sharedSecretKey: AppConfiguration.sharedSecretKey)
        self.remoteService = MockupRemoteService(purchaseService: self.purchaseService)
    }
    
    func reload() {
        self.setup()
        self.didBeginLoading?()
        self.purchaseService.loadProducts()
    }
}

private extension SubscriptionsViewModel {
    
    func setup() {
        self.purchaseService.setupCallbacks(
            didUpdateProductsList: { [weak self] result in
                switch result {
                case let .success(products):
                    print("selectedProduct - \(products.map({ $0.expiresDate }))")
                    self?.selectedProduct = products.first(where: { $0.skProduct.isSubscription })
                    self?.didProductsLoaded?()
                    self?.didStopLoading?()
                case let .failure(error):
                    print("didFailedFetchProducts - \(error.localizedDescription))")
                    self?.didStopLoading?()
                }
            },
            didCompletePurchase: { [weak self] result in
                switch result {
                case let .success(products):
                    print("didProductPurchased - \(products.map({ $0.debugDescription }))")
                    self?.validateReceipt()
                case let .failure(error):
                    if !error.isCancelled {
                        print("didFailedBuyPurchase - \(error.localizedDescription))")
                    }
                    self?.didStopLoading?()
                }
            },
            didRestorePurchases: { [weak self] result in
                switch result {
                case let .success(products):
                    print("didProductsRestored - \(products.map({ $0.debugDescription }))")
                    self?.validateReceipt()
                case let .failure(error):
                    if !error.isCancelled {
                        print("didFailedRestorePurchase - \(error.localizedDescription))")
                    }
                    self?.didStopLoading?()
                }
            }
        )
    }
    
    func validateReceipt() {
        self.purchaseService.fetchReceipt(validationType: .manual) { result in
            print("result - \(result)")
            switch result {
            case let .success(data):
                self.remoteService.validateReceipt(data) { purchasedProducts in
                    print("purchasedProducts - \(String(describing: purchasedProducts))")
                    DispatchQueue.main.async { [weak self] in
                        self?.didProductsLoaded?()
                        self?.didStopLoading?()
                    }
                }
            case let .failure(error):
                print("failed fetch receipt - \(String(describing: error.localizedDescription))")
                DispatchQueue.main.async { [weak self] in
                    self?.didProductsLoaded?()
                    self?.didStopLoading?()
                }
            }
        }
    }
}
