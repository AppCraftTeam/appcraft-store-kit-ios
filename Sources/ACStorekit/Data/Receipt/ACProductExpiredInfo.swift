//
//  ACProductExpiredInfo.swift
//
//
//  Created by Pavel Moslienko on 02.09.2024.
//

import Foundation

/// Represents information about a product that has expired
public struct ACProductExpiredInfo: Hashable {
    
    /// The unique identifier for the product
    public var productId: String
    
    /// The expiration date of the product
    public var date: Date
    
    static public func == (lhs: ACProductExpiredInfo, rhs: ACProductExpiredInfo) -> Bool {
        lhs.productId == rhs.productId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(productId)
    }
}
