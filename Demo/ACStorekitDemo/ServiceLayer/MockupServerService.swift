//
//  MockupRemoteService.swift
//  ACStorekitDemo
//
//  Created by Pavel Moslienko on 13.08.2024.
//

import Foundation
import ACStorekit

final class MockupRemoteService {
    
    var purchaseService: ACPurchaseService
    
    init(purchaseService: ACPurchaseService) {
        self.purchaseService = purchaseService
    }
    
    // In a real case, this is all done by the server, but for the example, we'll do the validation process ourselves
    func validateReceipt(_ info: ACReceiptProductInfo, competition: ((_ purchasedProducts: Set<ACProductExpiredInfo>?) -> Void)?) {
        // Recipe would be sent to the server
        // let receipt = info.receipt
        print("validateReceipt....")
        purchaseService.fetchReceipt(validationType: .apple) { result in
            switch result {
            case let .success(data):
                print("expiredInfo - \(data.expiredInfo)")
                competition?(data.expiredInfo)
            case let .failure(error):
                print("failed fetch receipt - \(String(describing: error.localizedDescription))")
                competition?(nil)
            }
        }
    }
}
