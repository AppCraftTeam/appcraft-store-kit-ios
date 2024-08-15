//
//  MockupRemoteService.swift
//  ACStorekitDemo
//
//  Created by Pavel Moslienko on 13.08.2024.
//

import Foundation
import ACStorekit

final class MockupRemoteService {
    
    var purchaseService: PurchaseService
    
    init(purchaseService: PurchaseService) {
        self.purchaseService = purchaseService
    }
    
    // In a real case, this is all done by the server, but for the example, we'll do the validation process ourselves
    func validateReceipt(_ receipt: Data, competition: ((_ purchasedProducts: [String]?) -> Void)?) {
        purchaseService.fetchReceipt(validationType: .apple) { result in
            switch result {
            case .success:
                let activeProducts = self.purchaseService.products.getActiveProducts()
                print("activeProductsss - \(activeProducts.map({ $0.product.productIdentifer }))")
                competition?(activeProducts.map({ $0.product.productIdentifer }))
            case let .failure(error):
                print("failed fetch receipt - \(String(describing: error.localizedDescription))")
                competition?([])
            }
        }
    }
}
