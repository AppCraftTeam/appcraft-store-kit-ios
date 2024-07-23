//
//  ACPurchases.swift
//  
//
//  Created by Pavel Moslienko on 22.07.2024.
//

import Foundation
import StoreKit

/// Filled in library
public protocol ACPurchaseType {
    var product: ACProduct { get }
    var skProduct: SKProduct { get }
}

open class ACPurchases: ACPurchaseType, Hashable {
    public var product: ACProduct
    public var skProduct: SKProduct
    private(set) public var expiresDate: Date?
    private(set) public var isActive: Bool
    
    public var debugDescription: String {
        "[ACPurchase] ID: \(skProduct.productIdentifier), isActive: \(isActive), expiresDate: \(expiresDate)\n"
    }
    
    public init(product: ACProduct, skProduct: SKProduct, expiresDate: Date? = nil, isActive: Bool = false) {
        self.product = product
        self.skProduct = skProduct
        self.expiresDate = expiresDate
        self.isActive = isActive
    }
    
    public func updateActive(_ isActive: Bool, expiresDate: Date?) {
        self.isActive = isActive
        self.expiresDate = expiresDate
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
    
    public func getActiveProducts() -> [ACPurchases] {
        self.filter({ $0.isActive })
    }
}
