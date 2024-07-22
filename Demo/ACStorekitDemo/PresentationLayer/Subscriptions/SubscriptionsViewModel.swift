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
        self.service.output = self
    }
    
    func reload() {
        self.didBeginLoading?()
        self.service.loadProducts()
    }
}

// MARK: - PurchaseServiceOutput
extension SubscriptionsViewModel: PurchaseServiceOutput {
    func error(_ service: ACStorekit.PurchaseService, error: Error?) {
        print("PurchaseService error - \(String(describing: error?.localizedDescription))")
        self.didStopLoading?()
    }
    
    func reload(_ service: ACStorekit.PurchaseService) {
        print("PurchaseService reloaded")
        DispatchQueue.main.async { [weak self] in
            self?.selectedProduct = service.products.first
            self?.didProductsLoaded?()
            self?.didStopLoading?()
        }
    }
    
    func purchase(_ service: ACStorekit.PurchaseService) {
        print("PurchaseService purchased")
        DispatchQueue.main.async { [weak self] in
            self?.didStopLoading?()
        }
    }
    
    func restore(_ service: ACStorekit.PurchaseService) {
        print("PurchaseService restored")
        DispatchQueue.main.async { [weak self] in
            self?.didStopLoading?()
        }
    }
}
