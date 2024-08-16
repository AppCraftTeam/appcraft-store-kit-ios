import Foundation
import StoreKit

open class ReceiptProductRequest: NSObject {
    public typealias Completion = (Result<Data, Error>) -> Void
    
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
        
        receiptService.fetchReceipt { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(receiptData):
                self.handleReceiptData(receiptData, validationType: validationType)
            case let .failure(error):
                self.finish(result: .failure(error))
            }
        }
    }
    
    open func getReceiptData() -> Data? {
        receiptService.receiptData
    }
}

private extension ReceiptProductRequest {
    
    func handleReceiptData(_ receiptData: Data, validationType: ReceiptValidationType) {
        switch validationType {
        case .manual:
            finish(result: .success(receiptData))
            
        case .apple:
            validationService.validateReceipt(receiptData) { [weak self] validationResult in
                guard let self = self else { return }
                
                switch validationResult {
                case let .success(json):
                    self.updateService.updateReceiptInfo(with: json) { error in
                        if let error = error {
                            self.finish(result: .failure(error))
                        } else {
                            self.finish(result: .success(receiptData))
                        }
                    }
                    
                case let .failure(error):
                    self.finish(result: .failure(error))
                }
            }
        }
    }
    
    func finish(result: Result<Data, Error>) {
        completion?(result)
        completion = nil
    }
}
