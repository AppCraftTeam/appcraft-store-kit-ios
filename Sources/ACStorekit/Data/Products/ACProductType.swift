//
//  ACProductType.swift
//
//
//  Created by Pavel Moslienko on 22.07.2024.
//

import Foundation

/// Protocol to be used for represent a product
public protocol ACProductType {
    var product: ACProduct { get }
}

/// Represents a specific product type
open class ACProductTypeItem: ACProductType, Hashable {
    
    /// The product associated with this type
    public var product: ACProduct
    
    /// Initializes a new instance of `ACProductTypeItem`
    /// - Parameter product: The associated product
    public init(product: ACProduct) {
        self.product = product
    }
    
    public static func == (lhs: ACProductTypeItem, rhs: ACProductTypeItem) -> Bool {
        lhs.product.productIdentifer == rhs.product.productIdentifer
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(product.productIdentifer)
    }
}

public extension Array where Element == ACProductTypeItem {
    
    /// Sorts the array of `ACProductTypeItem` in place based on the `sortIndex` of the products
    mutating func sortDefault() {
        self.sort(by: { $0.product.sortIndex < $1.product.sortIndex })
    }
    
    /// Retrieves a product by its identifier from the array
    /// - Parameter productIdentifer: The unique identifier of the product
    func getProduct(for productIdentifer: String) -> ACProduct? {
        self.first(where: { $0.product.productIdentifer == productIdentifer })?.product
    }
}
