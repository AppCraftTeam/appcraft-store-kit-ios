//
//  ACReceiptValidationService.swift
//
//
//  Created by Pavel Moslienko on 08.08.2024.
//

import Foundation

/// `ACReceiptValidationService` is responsible for validating receipts using Apple server
open class ACReceiptValidationService {
    
    /// URLs for verifying receipts
    private let sandboxVerifyUrl = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")
    private let prodVerifyUrl = URL(string: "https://buy.itunes.apple.com/verifyReceipt")
    
    /// The shared secret key
    private let sharedSecretKey: String
    
    /// Initializes the `ACReceiptValidationService`
    /// - Parameter sharedSecretKey: The shared secret key
    public init(sharedSecretKey: String) {
        self.sharedSecretKey = sharedSecretKey
    }
    
    /// Validates the given receipt data with Apples server
    /// - Parameters:
    ///   - receiptData: The `Data` containing the receipt
    ///   - completion: A closure that is called with the result of the validation
    open func validateReceipt(_ receiptData: Data, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        
        guard let prodVerifyUrl = prodVerifyUrl,
              let sandboxVerifyUrl = sandboxVerifyUrl else {
            completion(.failure(NSError(domain: "Incorrect url", code: 0, userInfo: nil)))
            return
        }
        
        let receiptString = receiptData.base64EncodedString()
        
        // Create the payload required for receipt validation
        let requestData: [String: Any] = [
            "receipt-data": receiptString,  // Base64-encoded receipt data
            "password": self.sharedSecretKey,  // Shared secret to verify receipts for subscriptions
            "exclude-old-transactions": false  // Include expired or old transactions
        ]
        
        let httpBody = try? JSONSerialization.data(withJSONObject: requestData, options: [])
        
        // Try to validate the receipt with the production environment
        sendRequestReceiptInfoOfApple(url: prodVerifyUrl, httpBody: httpBody) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(json):
                if let status = json["status"] as? Int, status == 21007 {
                    // Retry validation with the sandbox environment if the receipt is for a sandboxed purchase
                    self.sendRequestReceiptInfoOfApple(url: sandboxVerifyUrl, httpBody: httpBody, completion: completion)
                } else {
                    // Successfully validated receipt with production
                    completion(.success(json))
                }
            case let .failure(error):
                // Propagate any errors encountered during receipt validation
                completion(.failure(error))
            }
        }
    }
    
    /// Sends the receipt data to the specified Apple server
    /// - Parameters:
    ///   - url: The URL to send the receipt
    ///   - httpBody: The request body
    ///   - completion: A closure that is called with the result of the request
    private func sendRequestReceiptInfoOfApple(url: URL, httpBody: Data?, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        // Perform the network request using URLSession
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                completion(.failure(error ?? NSError(domain: "ReceiptSendError", code: 0, userInfo: nil)))
                return
            }
            
            completion(.success(json))
        }
        .resume()
    }
}
