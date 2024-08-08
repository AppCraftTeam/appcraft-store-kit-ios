//
//  ReceiptUpdateService.swift
//
//
//  Created by Pavel Moslienko on 08.08.2024.
//

import Foundation

open class ReceiptUpdateService {
    public let keyReceiptMaxExpiresDate: String
    
    public init(keyReceiptMaxExpiresDate: String) {
        self.keyReceiptMaxExpiresDate = keyReceiptMaxExpiresDate
    }
    
    open func updateReceiptInfo(with json: [String: Any], completion: @escaping (Error?) -> Void) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
        
        guard let receipts = json["latest_receipt_info"] as? [[String: Any]] else {
            completion(nil)
            return
        }
        
        var expiresDates: [Date] = []
        
        for receipt in receipts {
            guard
                let productID = receipt["product_id"] as? String,
                let expiresDate = receipt["expires_date"] as? String,
                let expiresDateDt = formatter.date(from: expiresDate)
            else { continue }
            
            if expiresDateDt > Date() {
                expiresDates.append(expiresDateDt)
                UserDefaults.standard.set(expiresDateDt, forKey: productID)
            }
        }
        
        updateMaxExpiresDate(of: expiresDates)
        completion(nil)
    }
    
    private func updateMaxExpiresDate(of dates: [Date]) {
        guard let max = dates.max() else {
            UserDefaults.standard.removeObject(forKey: self.keyReceiptMaxExpiresDate)
            return
        }
        
        UserDefaults.standard.set(max, forKey: self.keyReceiptMaxExpiresDate)
    }
}
