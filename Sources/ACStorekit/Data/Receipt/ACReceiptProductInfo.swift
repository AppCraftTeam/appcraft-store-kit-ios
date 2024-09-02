//
//  ACReceiptProductInfo.swift
//
//
//  Created by Pavel Moslienko on 02.09.2024.
//

import Foundation

public struct ACReceiptProductInfo {
    public var expiredInfo: Set<ACProductExpiredInfo>
    public var receipt: Data
}
