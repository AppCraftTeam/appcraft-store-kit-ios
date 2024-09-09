//
//  ACProductExpiredInfo.swift
//
//
//  Created by Pavel Moslienko on 02.09.2024.
//

import Foundation

public struct ACProductExpiredInfo: Hashable {
    public var productId: String
    public var date: Date
    
    static public func == (lhs: ACProductExpiredInfo, rhs: ACProductExpiredInfo) -> Bool {
        lhs.productId == rhs.productId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(productId)
    }
}
