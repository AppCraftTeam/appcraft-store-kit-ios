//
//  ACPurchases.swift
//
//
//  Created by Pavel Moslienko on 22.07.2024.
//

import Foundation
import StoreKit

/// Protocol representing a purchasable product with additional details
public protocol ACPurchaseType {
    
    /// The product associated with the purchase
    var product: ACProduct { get }
    
    /// The StoreKit product
    var skProduct: SKProduct { get }
    
    /// Boolean value indicating whether the product is active (not expired).
    var isActiveProduct: Bool { get }
    
    /// The locally stored expiration date of the product
    var productExpiresDateFromLocal: Date? { get }
    
    /// Saves the expiration date of the product locally.
    func saveExpiresDate(_ date: Date?)
}

/// Represents an individual purchase, conforming to `ACPurchaseType`
open class ACPurchases: ACPurchaseType {
    
    /// The product associated with the purchase
    public var product: ACProduct
    
    /// The StoreKit product
    public var skProduct: SKProduct
    
    /// Provides a debug description of the purchase
    public var debugDescription: String {
        "[ACPurchase] ID: \(skProduct.productIdentifier), isActive: \(isActiveProduct), expiresDate: \(productExpiresDateFromLocal)\n"
    }
    
    /// Initializes a new `ACPurchases`
    /// - Parameters:
    ///   - product: The associated product.
    ///   - skProduct: The StoreKit product.
    public init(product: ACProduct, skProduct: SKProduct) {
        self.product = product
        self.skProduct = skProduct
    }
    
    /// Checks if the product is active by comparing the current date with the locally stored expiration date
    public var isActiveProduct: Bool {
        guard let expiresDate = productExpiresDateFromLocal else {
            return false
        }
        return expiresDate > Date()
    }
    
    /// Retrieves the expiration date of the product from `UserDefaults`
    public var productExpiresDateFromLocal: Date? {
        UserDefaults.standard.object(forKey: self.product.productIdentifer) as? Date
    }
    
    /// Saves or removes the expiration date of the product in `UserDefaults`
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
    
    public static func == (lhs: ACPurchases, rhs: ACPurchases) -> Bool {
        lhs.product.productIdentifer == rhs.product.productIdentifer
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(product.productIdentifer)
    }
}

public extension Array where Element == ACPurchases {
    
    /// Sorts the array of `ACPurchases` in place based on the `sortIndex` of the products
    mutating func sortDefault() {
        self.sort(by: { $0.product.sortIndex < $1.product.sortIndex })
    }
    
    /// Retrieves a purchase by its product identifier from the array
    /// - Parameter productIdentifer: The unique identifier of the product
    func getProduct(for productIdentifer: String) -> ACPurchases? {
        self.first(where: { $0.product.productIdentifer == productIdentifer })
    }
    
    /// Returns an array of purchases that are currently active (not expired)
    func getActiveProducts() -> [ACPurchases] {
        self.filter({ $0.isActiveProduct })
    }
}
