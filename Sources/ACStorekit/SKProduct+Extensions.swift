//
//  SKProduct+Extensions.swift
//  OSAGO
//
//  Created by Дмитрий Поляков on 25.05.2021.
//  Copyright © 2021 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import StoreKit

public extension SKProduct {
    
    public var type: PurchaseType? {
        PurchaseType(rawValue: self.productIdentifier)
    }

    public var priceDefaultString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price) ?? ""
    }
    
    public var priceFullString: String {
        "Включить за \(self.priceDefaultString) в месяц"
    }

    public var nameString: String {
        !self.localizedTitle.isEmpty ? self.localizedTitle : self.type?.name ?? ""
    }
    
    public var infoString: String {
        self.type?.info ?? ""
    }
    
}

public extension Array where Element == SKProduct {
    
    public mutating func sortDefault() {
        self.sort(by: { ($0.type?.sortHeight) ?? 0 < ($1.type?.sortHeight ?? 0) })
    }
    
}
