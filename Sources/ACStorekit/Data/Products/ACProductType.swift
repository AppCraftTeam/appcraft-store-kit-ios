//
//  ACProductType.swift
//  
//
//  Created by Pavel Moslienko on 22.07.2024.
//

import Foundation

public protocol ACProductType {
    var product: ACProduct { get }
}

open class ACProductTypeItem: ACProductType, Hashable {
    public var product: ACProduct
    
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
    
    public mutating func sortDefault() {
        self.sort(by: { ($0.product.sortIndex) ?? 0 < ($1.product.sortIndex) })
    }
    
    public func getProduct(for productIdentifer: String) -> ACProduct? {
        self.first(where: { $0.product.productIdentifer == productIdentifer })?.product
    }
}
