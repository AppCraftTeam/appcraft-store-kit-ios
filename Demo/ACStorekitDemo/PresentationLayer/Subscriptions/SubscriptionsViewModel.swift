//
//  SubscriptionsViewModel.swift
//  ACStorekitDemo
//
//  Created by Pavel Moslienko on 18.07.2024.
//

import ACStorekit
import Foundation

final class SubscriptionsViewModel {
    
    var products: [AnyObject] = []
    var service: PurchaseService?

    init() {
        let products = Set(AppPurchases.allCases.map({ ACProductTypeItem(product: $0.product) }))
        print("products - \(products) \(Set(AppPurchases.allCases))")
        self.service = PurchaseService(sharedSecretKey: AppConfiguration.sharedSecretKey, products: products)
        self.service?.loadProducts()
    }
}
