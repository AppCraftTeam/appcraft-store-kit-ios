//
//  ACReceiptProductInfo.swift
//
//
//  Created by Pavel Moslienko on 02.09.2024.
//

import Foundation

/// Represents information about a receipt
public struct ACReceiptProductInfo {
    
    /// A set of expired products associated with the receipt
    public var expiredInfo: Set<ACProductExpiredInfo>
    
    /// The receipt file data
    public var receipt: Data
}
