//
//  Error+Extensions.swift
//
//
//  Created by Pavel Moslienko on 16.08.2024.
//

import Foundation

public extension Error {
    
    public var isCancelled: Bool {
        // paymentCancelled
        let notProvidesErrorCodes: [Int] = [2]
        return notProvidesErrorCodes.contains((self as NSError).code)
    }
}
