//
//  ACLogLevel.swift
//
//
//  Created by Pavel Moslienko on 03.09.2024.
//

import Foundation

/// Enum that defines the logging levels
public enum ACLogLevel {
    
    /// Disables logging
    case disable
    
    /// Logs only errors
    case onlyError
    
    /// Log all information
    case full
    
    /// A Boolean property that determines whether error messages should be printed.
    public var isAllowPrintError: Bool {
        self == .full || self == .onlyError
    }
}
