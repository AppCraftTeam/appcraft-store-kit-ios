//
//  ACReceiptValidationType.swift
//
//
//  Created by Pavel Moslienko on 13.08.2024.
//

import Foundation

/// Enum that defines the types of receipt validation
public enum ACReceiptValidationType {
    /// Manual receipt validation
    case manual
    /// Validation through Apple service via http request
    case apple
}
