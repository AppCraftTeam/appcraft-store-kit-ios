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
    
    public var priceDefaultString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        
        return formatter.string(from: self.price) ?? ""
    }
    
    public var isSubscription: Bool {
        self.subscriptionPeriod != nil
    }
}
