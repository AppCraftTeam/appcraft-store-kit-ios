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
    var service: PurchaseService = PurchaseService(sharedSecretKey: AppConfiguration.sharedSecretKey, products: products)
    var selectedProduct: ACPurchases?
    
    // MARK: - Callbacks
    var didProductsLoaded: (() -> Void)?
    var didBeginLoading: (() -> Void)?
    var didStopLoading: (() -> Void)?
    
    private static var products: Set<ACProductTypeItem> {
        Set(AppPurchases.allCases.map({ ACProductTypeItem(product: $0.product) }))
    }
    
    init() {
        self.service = PurchaseService(sharedSecretKey: AppConfiguration.sharedSecretKey, products: SubscriptionsViewModel.products)
    }
    
    func reload() {
        self.didBeginLoading?()
        
        self.service.setupCallbacks(
            didProductsListUpdated: { products in
                DispatchQueue.main.async { [weak self] in
                    self?.selectedProduct = products.first(where: { $0.skProduct.isSubscription })
                    self?.didProductsLoaded?()
                    self?.didStopLoading?()
                }
                
            },
            didProductPurchased: {  product in
                DispatchQueue.main.async { [weak self] in
                    self?.didStopLoading?()
                }
                
            },
            didProductsRestored: { product in
                DispatchQueue.main.async { [weak self] in
                    self?.didStopLoading?()
                }
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
        
        self.service.loadProducts()
    }
}
