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
        self.didBeginLoading?()
        
        self.purchaseService.setupCallbacks(
            didProductsListUpdated: { products in
                print("selectedProduct - \(products.map({ $0.expiresDate }))")
                DispatchQueue.main.async { [weak self] in
                    self?.selectedProduct = products.first(where: { $0.skProduct.isSubscription })
                    self?.didProductsLoaded?()
                    self?.didStopLoading?()
                }
                
            },
            didProductPurchased: {  products in
                print("didProductPurchased - \(products.map({ $0.debugDescription }))")
                self.validateReceipt()
            },
            didProductsRestored: { products in
                print("didProductsRestored - \(products.map({ $0.debugDescription }))")
                self.validateReceipt()
            },
            didFailedFetchProducts: { error in
                print("didFailedFetchProducts - \(String(describing: error?.localizedDescription))")
                DispatchQueue.main.async { [weak self] in
                    self?.didStopLoading?()
                }
            },
            didFailedBuyPurchase: { error in
                print("didFailedBuyPurchase - \(String(describing: error?.localizedDescription))")
                DispatchQueue.main.async { [weak self] in
                    self?.didStopLoading?()
                }
            },
            didFailedRestorePurchase: { error in
                print("didFailedRestorePurchase - \(String(describing: error?.localizedDescription))")
                DispatchQueue.main.async { [weak self] in
                    self?.didStopLoading?()
                }
            }
        )
        
        self.purchaseService.loadProducts()
    }
}

private extension SubscriptionsViewModel {
    
    func validateReceipt() {
        self.purchaseService.fetchReceipt(validationType: .manual) { result in
            print("result - \(result)")
            switch result {
            case let .success(data):
                    if let data = data {
                        self.remoteService.validateReceipt(data) { purchasedProducts in
                            print("purchasedProducts - \(purchasedProducts)")
                            DispatchQueue.main.async { [weak self] in
                                self?.didProductsLoaded?()
                                self?.didStopLoading?()
                            }
                        }
                    } else {
                        print("failed fetch receipt")
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
