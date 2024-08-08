import Foundation
import StoreKit

open class ReceiptProductRequest: NSObject {
    public typealias Completion = (Bool, Error?) -> Void
    
    private let receiptService: ReceiptService
    private let validationService: ReceiptValidationService
    public let updateService: ReceiptUpdateService // todo service private, keyReceiptMaxExpiresDate - make public (?)
    
    private var completion: Completion?
    
    public init(sharedSecretKey: String, keyReceiptMaxExpiresDate: String) {
        self.receiptService = ReceiptService()
        self.validationService = ReceiptValidationService(sharedSecretKey: sharedSecretKey)
        self.updateService = ReceiptUpdateService(keyReceiptMaxExpiresDate: keyReceiptMaxExpiresDate)
    }
    
    open func start(_ completion: Completion?) {
        self.completion = completion
        self.receiptService.fetchReceipt { [weak self] result in
            switch result {
            case .success(let receiptData):
                self?.validationService.validateReceipt(receiptData) { validationResult in
                    switch validationResult {
                    case .success(let json):
                        self?.updateService.updateReceiptInfo(with: json) { error in
                            if let error = error {
                                self?.completion?(false, error)
                            } else {
                                self?.completion?(true, nil)
                            }
                        }
                    case .failure(let error):
                        self?.completion?(false, error)
                    }
                }
            case .failure(let error):
                self?.completion?(false, error)
            }
        }
    }
}
