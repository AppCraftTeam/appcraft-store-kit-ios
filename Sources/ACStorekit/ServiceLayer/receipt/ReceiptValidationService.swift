//
//  ReceiptValidationService.swift
//
//
//  Created by Pavel Moslienko on 08.08.2024.
//

import Foundation

open class ReceiptValidationService {
    private let sandboxVerifyUrl = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
    private let prodVerifyUrl = URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
    private let sharedSecretKey: String
    
    public init(sharedSecretKey: String) {
        self.sharedSecretKey = sharedSecretKey
    }
    
    open func validateReceipt(_ receiptData: Data, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let receiptString = receiptData.base64EncodedString()
        let requestData: [String: Any] = [
            "receipt-data": receiptString,
            "password": self.sharedSecretKey,
            "exclude-old-transactions": false
        ]
        
        let httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])
        
        sendRequestReceiptInfoOfApple(url: prodVerifyUrl, httpBody: httpBody) { [weak self] result in
            guard let self = self else {
                return
            }
            
            switch result {
            case let .success(json):
                if let status = json["status"] as? Int, status == 21007 {
                    self.sendRequestReceiptInfoOfApple(url: self.sandboxVerifyUrl, httpBody: httpBody, completion: completion)
                } else {
                    completion(.success(json))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    private func sendRequestReceiptInfoOfApple(url: URL, httpBody: Data?, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
            else {
                completion(.failure(error ?? NSError(domain: "ReceiptSendError", code: 0, userInfo: nil)))
                return
            }
            
            completion(.success(json))
        }
        .resume()
    }
}
