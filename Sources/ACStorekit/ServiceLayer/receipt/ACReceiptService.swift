//
//  ACReceiptService.swift
//
//
//  Created by Pavel Moslienko on 08.08.2024.
//

import Foundation
import StoreKit

open class ACReceiptService: NSObject {
    
    private(set) public var receiptData: Data?
    
    private var receiptRefreshRequest: SKReceiptRefreshRequest?
    private var countReceiptRefreshRequest: Int = 0
    private let maxCountReceiptRefreshRequest: Int = 4
    
    private var didReceiptUpdated: (() -> Void)?
    private var didFailUpdateReceipt: ((_ error: Error) -> Void)?
    
    open func fetchReceipt(completion: @escaping (Result<Data, Error>) -> Void) {
        guard let receiptPath = Bundle.main.appStoreReceiptURL?.path,
              FileManager.default.fileExists(atPath: receiptPath),
              let receiptURL = Bundle.main.appStoreReceiptURL
        else {
            print("fetchReceipt failed")

            if countReceiptRefreshRequest >= maxCountReceiptRefreshRequest {
                completion(.failure(NSError(domain: "ReceiptFetchError", code: 0, userInfo: nil)))
                return
            }
            
            didReceiptUpdated = {
                print("didReceiptUpdated")
                self.fetchReceipt(completion: completion)
            }
            didFailUpdateReceipt = { error in
                print("didFailUpdateReceipt error \(error)")
                self.fetchReceipt(completion: completion)
            }
            
            refreshReceipt()
            return
        }
        print("fetchReceipt try getting data")

        do {
            let receiptData = try Data(contentsOf: receiptURL, options: .alwaysMapped)
            self.receiptData = receiptData
            completion(.success(receiptData))
        } catch {
            completion(.failure(error))
        }
    }
    
    private func refreshReceipt() {
        print("refreshReceipt....")
        countReceiptRefreshRequest += 1
        
        receiptRefreshRequest = SKReceiptRefreshRequest()
        receiptRefreshRequest?.delegate = self
        receiptRefreshRequest?.start()
    }
}

extension ACReceiptService: SKRequestDelegate {
    open func requestDidFinish(_ request: SKRequest) {
        print("ACReceiptService requestDidFinish")
        request.cancel()
        didReceiptUpdated?()
    }
    
    open func request(_ request: SKRequest, didFailWithError error: Error) {
        print("ACReceiptService didFailWithError - \(error)")
        didFailUpdateReceipt?(error)
    }
}
