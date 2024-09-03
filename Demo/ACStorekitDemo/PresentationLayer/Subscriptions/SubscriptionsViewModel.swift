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
    var purchaseService: ACPurchaseService
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
        self.purchaseService = ACPurchaseService(
            products: SubscriptionsViewModel.products,
            sharedSecretKey: AppConfiguration.sharedSecretKey,
            logLevel: .full
        )
        self.remoteService = MockupRemoteService(purchaseService: self.purchaseService)
    }
    
    func reload() {
        self.setup()
        self.didBeginLoading?()
        self.purchaseService.loadProducts()
        self.getActualSubscription()
    }
}

private extension SubscriptionsViewModel {
    
    func setup() {
        self.purchaseService.setupCallbacks(
            didUpdateProductsList: { [weak self] result in
                switch result {
                case let .success(products):
                    DispatchQueue.main.async { [weak self] in
                        self?.selectedProduct = products.first(where: { $0.skProduct.isSubscription })
                        self?.didProductsLoaded?()
                        self?.didStopLoading?()
                    }
                case .failure:
                    DispatchQueue.main.async { [weak self] in
                        self?.didStopLoading?()
                    }
                }
            },
            didCompletePurchase: { [weak self] result in
                switch result {
                case .success:
                    self?.validateReceipt()
                case .failure:
                    DispatchQueue.main.async { [weak self] in
                        self?.didStopLoading?()
                    }
                }
            },
            didRestorePurchases: { [weak self] result in
                switch result {
                case let .success(products):
                    print("[SubscriptionsViewModel] didProductsRestored - \(products.map({ $0.debugDescription }))")
                    self?.validateReceipt()
                case let .failure(error):
                    if !error.isCancelled {
                        print("[SubscriptionsViewModel] didFailedRestorePurchase - \(error.localizedDescription))")
                    }
                    DispatchQueue.main.async { [weak self] in
                        self?.didStopLoading?()
                    }
                }
            }
        )
    }
    
    func validateReceipt() {
        self.purchaseService.fetchReceipt(validationType: .manual) { result in
            switch result {
            case let .success(data):
                self.remoteService.validateReceipt(data) { purchasedProducts in
                    (purchasedProducts ?? []).forEach({ info in
                        self.purchaseService.products
                            .first(where: { $0.product.productIdentifer == info.productId })?
                            .saveExpiresDate(info.date)
                    })
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.didProductsLoaded?()
                        self?.didStopLoading?()
                    }
                }
            case let .failure(error):
                DispatchQueue.main.async { [weak self] in
                    self?.didProductsLoaded?()
                    self?.didStopLoading?()
                }
            }
        }
    }
    
    func getActualSubscription() {
        /*
         In a real application, there would be a request to the server to get a profile or information about the status of subscriptions,
         but for the example, it will again perform validation through Apple
         */
        DispatchQueue.main.async { [weak self] in
            self?.didBeginLoading?()
            self?.validateReceipt()
        }
    }
}
