//
//  ACLogLevel.swift
//
//
//  Created by Pavel Moslienko on 03.09.2024.
//

import Foundation

public enum ACLogLevel {
    case disable, onlyError, full
    
    public var isAllowPrintError: Bool {
        self == .full || self == .onlyError
    }
}
