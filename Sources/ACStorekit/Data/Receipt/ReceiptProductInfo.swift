//
//  ReceiptProductInfo.swift
//
//
//  Created by Pavel Moslienko on 02.09.2024.
//

import Foundation

public struct ReceiptProductInfo {
    public var expiredInfo: Set<ProductExpiredInfo>
    public var receipt: Data
}
