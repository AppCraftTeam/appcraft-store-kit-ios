//
//  ACReceiptUpdateService.swift
//
//
//  Created by Pavel Moslienko on 08.08.2024.
//

import Foundation

/// `ACReceiptUpdateService` is responsible for processing receipt information from a JSON response
open class ACReceiptUpdateService {
    
    /// Type alias for the completion handler
    public typealias Completion = (Result<Set<ACProductExpiredInfo>, Error>) -> Void
    
    /// Key used to store the maximum expiration date of the receipt in `UserDefaults`
    private let keyReceiptMaxExpiresDate: String
    
    /// Log level to control verbosity of the logging
    private var logLevel: ACLogLevel
    
    /// Initializes the `ACReceiptUpdateService`
    /// - Parameters:
    ///   - keyReceiptMaxExpiresDate: The key used to store the maximum expiration date in `UserDefaults`
    ///   - logLevel: The `ACLogLevel` to control logging verbosity
    public init(keyReceiptMaxExpiresDate: String, logLevel: ACLogLevel) {
        self.keyReceiptMaxExpiresDate = keyReceiptMaxExpiresDate
        self.logLevel = logLevel
    }
    
    /// Processes the receipt data from a JSON response,
    /// - Parameters:
    ///   - json: A dictionary containing the receipt information
    ///   - completion: A closure that is called with the result containing a set of `ACProductExpiredInfo` or an error
    open func updateReceiptInfo(with json: [String: Any], completion: @escaping Completion) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"  // Date format to parse expiration dates from the receipt JSON
        
        // Extract the receipt information array from the JSON
        guard let receipts = json["latest_receipt_info"] as? [[String: Any]] else {
            completion(.failure(NSError(domain: "Failed to fetch receipt info", code: -1)))
            return
        }
        
        var expiresInfo: Set<ACProductExpiredInfo> = []  // Set to hold product expiration info
        
        // Loop through each receipt and extract relevant information
        for receipt in receipts {
            guard
                let productID = receipt["product_id"] as? String,
                let expiresDate = receipt["expires_date"] as? String,
                let expiresDateDt = formatter.date(from: expiresDate)
            else {
                if self.logLevel.isAllowPrintError {
                    print("[ACReceiptUpdateService] failed to parse receipt: \(receipt)")
                }
                continue
            }
            
            // Only include products whose expiration date is in the future
            if expiresDateDt > Date() {
                expiresInfo.insert(ACProductExpiredInfo(productId: productID, date: expiresDateDt))
            }
        }
        
        // Update the maximum expiration date of the receipt info
        updateMaxExpiresDate(of: expiresInfo.map({ $0.date }))
        
        if self.logLevel == .full {
            print("[ACReceiptUpdateService] Created expiration info model: \(expiresInfo)")
        }
        
        completion(.success(expiresInfo))
    }
    
    /// Updates the maximum expiration date in `UserDefaults`
    /// - Parameters:
    ///   - dates: An array of `Date` objects to determine the maximum expiration date
    private func updateMaxExpiresDate(of dates: [Date]) {
        // If there are no dates, remove the key from UserDefaults
        guard let max = dates.max() else {
            UserDefaults.standard.removeObject(forKey: self.keyReceiptMaxExpiresDate)
            return
        }
        
        UserDefaults.standard.set(max, forKey: self.keyReceiptMaxExpiresDate)
    }
}
