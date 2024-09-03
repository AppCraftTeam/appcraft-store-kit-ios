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
    var isActiveProduct: Bool { get }
    var productExpiresDateFromLocal: Date?  { get }
    
    func saveExpiresDate(_ date: Date?)
}

open class ACPurchases: ACPurchaseType {
    public var product: ACProduct
    public var skProduct: SKProduct
    
    public var debugDescription: String {
        "[ACPurchase] ID: \(skProduct.productIdentifier), isActive: \(isActiveProduct), expiresDate: \(productExpiresDateFromLocal)\n"
    }
    
    public init(product: ACProduct, skProduct: SKProduct) {
        self.product = product
        self.skProduct = skProduct
    }
    
    public var isActiveProduct: Bool {
        guard let expiresDate = productExpiresDateFromLocal else {
            return false
        }
        return expiresDate > Date()
    }
    
    public var productExpiresDateFromLocal: Date? {
        UserDefaults.standard.object(forKey: self.product.productIdentifer) as? Date
    }
    
    public func saveExpiresDate(_ date: Date?) {
        if let date = date {
            UserDefaults.standard.set(date, forKey: self.product.productIdentifer)
        } else {
            UserDefaults.standard.removeObject(forKey: self.product.productIdentifer)
        }
    }
}

// MARK: - Hashable
extension ACPurchases: Hashable {
    
     static public func == (lhs: ACPurchases, rhs: ACPurchases) -> Bool {
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
        self.filter({ $0.isActiveProduct })
    }
}
