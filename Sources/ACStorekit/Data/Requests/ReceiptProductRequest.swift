import Foundation
import StoreKit

public struct ReceiptProductData {
    var receipt: Data?
    var isValid: Bool
}

open class ReceiptProductRequest: NSObject {
    public typealias Completion = (ReceiptProductData, Error?) -> Void
    
    private let receiptService: ReceiptService
    private let validationService: ReceiptValidationService
    private let updateService: ReceiptUpdateService
    
    private var completion: Completion?
        
    public init(sharedSecretKey: String, keyReceiptMaxExpiresDate: String) {
        self.receiptService = ReceiptService()
        self.validationService = ReceiptValidationService(sharedSecretKey: sharedSecretKey)
        self.updateService = ReceiptUpdateService(keyReceiptMaxExpiresDate: keyReceiptMaxExpiresDate)
    }
    
    open func start(validationType: ReceiptValidationType, _ completion: Completion?) {
        self.completion = completion
        self.receiptService.fetchReceipt { [weak self] result in
            switch result {
            case let .success(receiptData):
                switch validationType {
                case .manual:
                    self?.completion?(ReceiptProductData(receipt: receiptData, isValid: true), nil)
                case .apple:
                    self?.validationService.validateReceipt(receiptData) { validationResult in
                        switch validationResult {
                        case let .success(json):
                            self?.updateService.updateReceiptInfo(with: json) { error in
                                if let error = error {
                                    self?.completion?(ReceiptProductData(receipt: receiptData, isValid: false), error)
                                } else {
                                    self?.completion?(ReceiptProductData(receipt: receiptData, isValid: true), nil)
                                }
                            }
                        case let .failure(error):
                            self?.completion?(ReceiptProductData(receipt: receiptData, isValid: false), error)
                        }
                    }
                }
            case let .failure(error):
                self?.completion?(ReceiptProductData(receipt: nil, isValid: false), error)
            }
        }
    }
    
    open func getReceiptData() -> Data? {
        self.receiptService.receiptData
    }
}
