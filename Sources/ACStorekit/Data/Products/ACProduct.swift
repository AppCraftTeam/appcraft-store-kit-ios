//
//  ACProduct.swift
//
//
//  Created by Pavel Moslienko on 18.07.2024.
//

import Foundation
import StoreKit

/// Filled in user application
open class ACProduct {
    open var productIdentifer: String
    open var name: String
    open var description: String
    open var sortIndex: Int
    
    public init(productIdentifer: String, name: String, description: String, sortIndex: Int) {
        self.productIdentifer = productIdentifer
        self.name = name
        self.description = description
        self.sortIndex = sortIndex
    }
}
