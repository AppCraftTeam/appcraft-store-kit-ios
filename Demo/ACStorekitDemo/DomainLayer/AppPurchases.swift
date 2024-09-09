//
//  AppPurchases.swift
//  ACStorekitDemo
//
//  Created by Pavel Moslienko on 18.07.2024.
//

import ACStorekit
import Foundation
import StoreKit

public enum AppPurchases: String, CaseIterable, ACProductType {
    case monthPremium = "appcraft.storeDemo.subscription.month"
    case yearPremium = "appcraft.storeDemo.subscription.year"
    case fullPremium = "appcraft.storeDemo.purchase.full"
    
    public var product: ACProduct {
        switch self {
        case .monthPremium:
            return ACProduct(
                productIdentifer: self.rawValue,
                name: "Month",
                description: "",
                sortIndex: 0
            )
        case .yearPremium:
            return ACProduct(
                productIdentifer: self.rawValue,
                name: "Year",
                description: "",
                sortIndex: 1
            )
        case .fullPremium:
            return ACProduct(
                productIdentifer: self.rawValue,
                name: "Full",
                description: "",
                sortIndex: 2
            )
        }
    }
}
