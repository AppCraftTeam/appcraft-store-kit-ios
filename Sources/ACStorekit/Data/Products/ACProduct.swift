//
//  ACProduct.swift
//
//
//  Created by Pavel Moslienko on 18.07.2024.
//

import Foundation
import StoreKit

public protocol ACProductItem {
    var productIdentifer: String { get }
    var name: String { get }
    var description: String { get }
    var sortIndex: Int { get }
}

/// Filled in user application
open class ACProduct: ACProductItem {
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
