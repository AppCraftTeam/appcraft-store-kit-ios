//
//  Error+Extensions.swift
//
//
//  Created by Pavel Moslienko on 16.08.2024.
//

import Foundation

public extension Error {
    
    /// Checks if the error was caused by a cancelled operation
    public var isCancelled: Bool {
        let notProvidesErrorCodes: [Int] = [2] // paymentCancelled
        return notProvidesErrorCodes.contains((self as NSError).code)
    }
}
