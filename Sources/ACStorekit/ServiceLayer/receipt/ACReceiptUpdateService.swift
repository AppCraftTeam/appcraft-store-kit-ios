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
    
    public init(keyReceiptMaxExpiresDate: String) {
        self.keyReceiptMaxExpiresDate = keyReceiptMaxExpiresDate
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
            else { continue }
            
            if expiresDateDt > Date() {
                expiresInfo.insert(ACProductExpiredInfo(productId: productID, date: expiresDateDt))
                // UserDefaults.standard.set(expiresDateDt, forKey: productID)
            }
        }
        
        updateMaxExpiresDate(of: expiresInfo.map({ $0.date }))
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
