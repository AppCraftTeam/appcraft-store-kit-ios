//
//  ACReceiptService.swift
//
//
//  Created by Pavel Moslienko on 08.08.2024.
//

import Foundation
import StoreKit

/// `ACReceiptService` is responsible for managing and fetching the App Store receipt.
open class ACReceiptService: NSObject {
    
    /// Holds the latest receipt data
    private(set) public var receiptData: Data?
    
    /// Log level to control verbosity of the logging
    private var logLevel: ACLogLevel
    
    /// Used to refresh the receipt from the App Store if it doesn't exist or is outdated
    private var receiptRefreshRequest: SKReceiptRefreshRequest?
    
    /// Counter to track how many times a refresh request has been attempted
    private var countReceiptRefreshRequest: Int = 0
    
    /// Maximum number of times a refresh request can be attempted before failure is returned
    private let maxCountReceiptRefreshRequest: Int = 4
    
    /// Closure to execute when the receipt is successfully updated
    private var didReceiptUpdated: (() -> Void)?
    
    /// Closure to execute when updating the receipt fails
    private var didFailUpdateReceipt: ((_ error: Error) -> Void)?
    
    /// Initializes the `ACReceiptService`
    /// - Parameters:
    ///   - logLevel: The `ACLogLevel` to control logging verbosity.
    public init(logLevel: ACLogLevel) {
        self.logLevel = logLevel
    }
    
    /// Fetches the receipt data from the app bundle
    open func fetchReceipt(completion: @escaping (Result<Data, Error>) -> Void) {
        if self.logLevel == .full {
            print("[ACReceiptService] fetching receipt started")
        }
        
        // Check if the receipt exists in the apps bundle
        guard let receiptPath = Bundle.main.appStoreReceiptURL?.path,
              FileManager.default.fileExists(atPath: receiptPath),
              let receiptURL = Bundle.main.appStoreReceiptURL
        else {
            // Log error and refresh receipt if necessary
            if self.logLevel.isAllowPrintError {
                print("[ACReceiptService] Fetching receipt failed")
            }
            
            // If the max number of refresh attempts is reached, return failure
            if countReceiptRefreshRequest >= maxCountReceiptRefreshRequest {
                completion(.failure(NSError(domain: "ReceiptFetchError", code: 0, userInfo: nil)))
                return
            }
            
            // Set closures to re-attempt fetching or handle failure after refreshing the receipt
            didReceiptUpdated = {
                self.fetchReceipt(completion: completion)
            }
            didFailUpdateReceipt = { error in
                self.fetchReceipt(completion: completion)
            }
            
            // Attempt to refresh the receipt
            refreshReceipt()
            return
        }
        
        // If the receipt is found, read it from the file system
        do {
            let receiptData = try Data(contentsOf: receiptURL, options: .alwaysMapped)
            self.receiptData = receiptData
            completion(.success(receiptData))
        } catch {
            // Handle any errors that occur while reading the receipt
            completion(.failure(error))
        }
    }
    
    /// Refreshes the receipt by sending a `SKReceiptRefreshRequest` to the App Store.
    private func refreshReceipt() {
        if self.logLevel == .full {
            print("[ACReceiptService] refresh receipt started")
        }
        countReceiptRefreshRequest += 1
        
        // Initialize and start the receipt refresh request
        receiptRefreshRequest = SKReceiptRefreshRequest()
        receiptRefreshRequest?.delegate = self
        receiptRefreshRequest?.start()
    }
}

// MARK: - SKRequestDelegate
extension ACReceiptService: SKRequestDelegate {
    
    /// Called when the receipt refresh request finishes successfully
    open func requestDidFinish(_ request: SKRequest) {
        if self.logLevel == .full {
            print("[ACReceiptService] receipt success updating")
        }
        request.cancel()
        didReceiptUpdated?()
    }
    
    /// Called when the receipt refresh request fails
    open func request(_ request: SKRequest, didFailWithError error: Error) {
        if self.logLevel.isAllowPrintError {
            print("[ACReceiptService] failed updating receipt: \(error)")
        }
        didFailUpdateReceipt?(error)
    }
}
