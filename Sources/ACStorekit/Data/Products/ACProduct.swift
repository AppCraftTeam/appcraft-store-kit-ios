//
//  ACProduct.swift
//
//
//  Created by Pavel Moslienko on 18.07.2024.
//

import Foundation
import StoreKit

/// Represents a product with basic details such as identifier, name, description, and sort index.
open class ACProduct {
    
    /// Unique identifier for the product
    open var productIdentifer: String
    
    /// Name of the product
    open var name: String
    
    /// Description of the product
    open var description: String
    
    /// Index used for sorting the products
    open var sortIndex: Int
    
    /// Initializes a new instance of `ACProduct`
    /// - Parameters:
    ///   - productIdentifer: Unique identifier for the product
    ///   - name: Name of the product.
    ///   - description: Description of the product
    ///   - sortIndex: Sorting index
    public init(productIdentifer: String, name: String, description: String, sortIndex: Int) {
        self.productIdentifer = productIdentifer
        self.name = name
        self.description = description
        self.sortIndex = sortIndex
    }
}
