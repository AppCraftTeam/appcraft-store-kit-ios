//
//  ACReceiptUpdateService.swift
//
//
//  Created by Pavel Moslienko on 08.08.2024.
//

import Foundation

open class ACReceiptUpdateService {
    public typealias Completion = (Result<Set<ACProductExpiredInfo>, Error>) -> Void
    private let keyReceiptMaxExpiresDate: String
    private var logLevel: ACLogLevel

    public init(keyReceiptMaxExpiresDate: String, logLevel: ACLogLevel) {
        self.keyReceiptMaxExpiresDate = keyReceiptMaxExpiresDate
        self.logLevel = logLevel
    }
    
    open func updateReceiptInfo(with json: [String: Any], completion: @escaping Completion) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
        
        guard let receipts = json["latest_receipt_info"] as? [[String: Any]] else {
            completion(.failure(NSError(domain: "Failed fet receipt info", code: -1)))
            return
        }

        var expiresInfo: Set<ACProductExpiredInfo> = []
        
        for receipt in receipts {
            guard
                let productID = receipt["product_id"] as? String,
                let expiresDate = receipt["expires_date"] as? String,
                let expiresDateDt = formatter.date(from: expiresDate)
            else {
                if self.logLevel.isAllowPrintError {
                    print("[ACReceiptUpdateService] failed parce receipt: \(receipt)")
                }
                continue
            }
            
            if expiresDateDt > Date() {
                expiresInfo.insert(ACProductExpiredInfo(productId: productID, date: expiresDateDt))
            }
        }
        
        updateMaxExpiresDate(of: expiresInfo.map({ $0.date }))
        if self.logLevel == .full {
            print("[ACReceiptUpdateService] Created expires info model: \(expiresInfo)")
        }
        completion(.success(expiresInfo))
    }
    
    private func updateMaxExpiresDate(of dates: [Date]) {
        guard let max = dates.max() else {
            UserDefaults.standard.removeObject(forKey: self.keyReceiptMaxExpiresDate)
            return
        }
        
        UserDefaults.standard.set(max, forKey: self.keyReceiptMaxExpiresDate)
    }
}
