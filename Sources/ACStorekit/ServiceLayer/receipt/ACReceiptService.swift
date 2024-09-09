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
    private var logLevel: ACLogLevel

    private var receiptRefreshRequest: SKReceiptRefreshRequest?
    private var countReceiptRefreshRequest: Int = 0
    private let maxCountReceiptRefreshRequest: Int = 4
    
    private var didReceiptUpdated: (() -> Void)?
    private var didFailUpdateReceipt: ((_ error: Error) -> Void)?
    
    public init(logLevel: ACLogLevel) {
        self.logLevel = logLevel
    }
    
    open func fetchReceipt(completion: @escaping (Result<Data, Error>) -> Void) {
        if self.logLevel == .full {
            print("[ACReceiptService] fetching receipt started")
        }
        guard let receiptPath = Bundle.main.appStoreReceiptURL?.path,
              FileManager.default.fileExists(atPath: receiptPath),
              let receiptURL = Bundle.main.appStoreReceiptURL
        else {
            if self.logLevel.isAllowPrintError {
                print("[ACReceiptService] Fetching receipt failed")
            }

            if countReceiptRefreshRequest >= maxCountReceiptRefreshRequest {
                completion(.failure(NSError(domain: "ReceiptFetchError", code: 0, userInfo: nil)))
                return
            }
            
            didReceiptUpdated = {
                self.fetchReceipt(completion: completion)
            }
            didFailUpdateReceipt = { error in
                self.fetchReceipt(completion: completion)
            }
            
            refreshReceipt()
            return
        }

        do {
            let receiptData = try Data(contentsOf: receiptURL, options: .alwaysMapped)
            self.receiptData = receiptData
            completion(.success(receiptData))
        } catch {
            completion(.failure(error))
        }
    }
    
    private func refreshReceipt() {
        if self.logLevel == .full {
            print("[ACReceiptService] refresh receipt started")
        }
        countReceiptRefreshRequest += 1
        
        receiptRefreshRequest = SKReceiptRefreshRequest()
        receiptRefreshRequest?.delegate = self
        receiptRefreshRequest?.start()
    }
}

extension ACReceiptService: SKRequestDelegate {
    open func requestDidFinish(_ request: SKRequest) {
        if self.logLevel == .full {
            print("[ACReceiptService] receipt success updating")
        }
        request.cancel()
        didReceiptUpdated?()
    }
    
    open func request(_ request: SKRequest, didFailWithError error: Error) {
        if self.logLevel.isAllowPrintError {
            print("[ACReceiptService] failed updating receipt: \(error)")
        }
        didFailUpdateReceipt?(error)
    }
}
