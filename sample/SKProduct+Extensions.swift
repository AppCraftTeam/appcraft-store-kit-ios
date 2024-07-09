//
//  SKProduct+Extensions.swift
//  OSAGO
//
//  Created by Дмитрий Поляков on 25.05.2021.
//  Copyright © 2021 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import StoreKit

extension SKProduct {
    
    var type: PurchaseType? {
        PurchaseType(rawValue: self.productIdentifier)
    }

    var priceDefaultString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price) ?? ""
    }
    
    var priceFullString: String {
        "Включить за \(self.priceDefaultString) в месяц"
    }

    var nameString: String {
        !self.localizedTitle.isEmpty ? self.localizedTitle : self.type?.name ?? ""
    }
    
    var infoString: String {
        self.type?.info ?? ""
    }
    
}

extension Array where Element == SKProduct {
    
    mutating func sortDefault() {
        self.sort(by: { ($0.type?.sortHeight) ?? 0 < ($1.type?.sortHeight ?? 0) })
    }
    
}
