//
//  ACPurchases.swift
//  
//
//  Created by Pavel Moslienko on 22.07.2024.
//

import Foundation
import StoreKit

open class ACPurchases: ACPurchaseType, Hashable {
    public var product: ACProduct
    public var skProduct: SKProduct
    
    public init(product: ACProduct, skProduct: SKProduct) {
        self.product = product
        self.skProduct = skProduct
    }
    
    public static func == (lhs: ACPurchases, rhs: ACPurchases) -> Bool {
        lhs.product.productIdentifer == rhs.product.productIdentifer
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(product.productIdentifer)
    }
}

public extension Array where Element == ACPurchases {
    
    public mutating func sortDefault() {
        self.sort(by: { ($0.product.sortIndex) ?? 0 < ($1.product.sortIndex) })
    }
    
    public func getProduct(for productIdentifer: String) -> ACPurchases? {
        self.first(where: { $0.product.productIdentifer == productIdentifer })
    }
}
