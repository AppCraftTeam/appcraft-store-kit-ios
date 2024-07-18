import Foundation
import StoreKit

open class ReceiptProductRequest: NSObject {
    public typealias Completion = (Bool, Error?) -> Void
    
    private let sandboxVerifyUrl = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")
    private let prodVerifyUrl = URL(string: "https://buy.itunes.apple.com/verifyReceipt")
    
    private var countReceiptRefreshRequest: Int = 0
    private let maxCountReceiptRefreshRequest: Int = 4
    
    private let sharedSecretKey: String
    private var receiptRefreshRequest: SKReceiptRefreshRequest?
    private var completion: Completion?
    
    public let keyReceiptMaxExpiresDate: String
    
    public init(sharedSecretKey: String, keyReceiptMaxExpiresDate: String) {
        self.sharedSecretKey = sharedSecretKey
        self.keyReceiptMaxExpiresDate = keyReceiptMaxExpiresDate
    }
    
    open func start(_ completion: Completion?) {
        self.completion = completion
        self.countReceiptRefreshRequest = 0
        self.createReceiptData()
    }
    
    private func finish(result: Bool, error: Error?) {
        self.completion?(result, error)
        self.completion = nil
    }
    
    private func createReceiptData() {
        guard
            let receiptPath = Bundle.main.appStoreReceiptURL?.path,
            FileManager.default.fileExists(atPath: receiptPath),
            let receiptURL = Bundle.main.appStoreReceiptURL
        else {
            guard self.countReceiptRefreshRequest <= self.maxCountReceiptRefreshRequest else {
                self.completion?(false, nil)
                return
            }
            
            self.refreshReceipt()
            return
        }
        
        do {
            let receiptData = try Data(contentsOf: receiptURL, options: Data.ReadingOptions.alwaysMapped)
            let data = receiptData.base64EncodedString(options: Data.Base64EncodingOptions.endLineWithCarriageReturn)
            self.loadReceiptInfoOfApple(receiptData: data)
        } catch {
            self.finish(result: false, error: nil)
        }
    }
    
    private func refreshReceipt() {
        self.countReceiptRefreshRequest += 1
        
        self.receiptRefreshRequest = SKReceiptRefreshRequest()
        self.receiptRefreshRequest?.delegate = self
        self.receiptRefreshRequest?.start()
    }
    
    private func loadReceiptInfoOfApple(receiptData: String?) {
        guard
            let receiptData = receiptData,
            let prodUrl = self.prodVerifyUrl,
            let sandboxUrl = self.sandboxVerifyUrl
        else {
            self.finish(result: false, error: nil)
            return
        }
        
        let requestData: [String: Any] = [
            "receipt-data": receiptData,
            "password": self.sharedSecretKey,
            "exclude-old-transactions": false
        ]
        
        let httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])
        
        /// Send to **prod**
        self.sendRequestReceiptInfoOfApple(url: prodUrl, httpBody: httpBody) { [weak self] json, error in
            guard let self = self else { return }
            
            guard error == nil else {
                self.finish(result: false, error: error)
                return
            }
            
            /// Check availible status
            if let status = json["status"] as? Int, status != 21007 {
                self.parseReceiptInfo(json) { [weak self] error in
                    guard error == nil else {
                        self?.finish(result: false, error: error)
                        return
                    }
                    
                    self?.finish(result: true, error: nil)
                }
            } else {
                /// Send to **sanbox**
                self.sendRequestReceiptInfoOfApple(url: sandboxUrl, httpBody: httpBody) { [weak self] json, error in
                    guard let self = self else { return }
                    
                    guard error == nil else {
                        self.finish(result: false, error: error)
                        return
                    }
                    
                    self.parseReceiptInfo(json) { [weak self] error in
                        guard error == nil else {
                            self?.finish(result: false, error: error)
                            return
                        }
                        
                        self?.finish(result: true, error: nil)
                    }
                }
            }
        }
    }
    
    private func sendRequestReceiptInfoOfApple(url: URL, httpBody: Data?, completion: @escaping ([String: Any], Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            else {
                completion([:], error)
                return
            }
            
            completion(json, nil)
        }.resume()
    }
    
    private func parseReceiptInfo(_ json: [String: Any], completion: @escaping (Error?) -> Void) {
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
            
            guard expiresDateDt > Date() else { continue }
            
            expiresDates += [expiresDateDt]
            UserDefaults.standard.set(expiresDateDt, forKey: productID)
        }
        
        self.updateMaxExpiresDate(of: expiresDates)
        
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

extension ReceiptProductRequest: SKRequestDelegate {
    
    public func requestDidFinish(_ request: SKRequest) {
        request.cancel()
        self.createReceiptData()
    }
    
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        self.finish(result: false, error: error)
    }
}
