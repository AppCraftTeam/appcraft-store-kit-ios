import Foundation
import StoreKit

open class ReceiptProductRequest: NSObject {
    public typealias Completion = (Result<ReceiptProductInfo, Error>) -> Void
    
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
        print("fetchReceiptfetchReceipt start...")

        receiptService.fetchReceipt { [weak self] result in
            print("fetchReceiptfetchReceipt result - \(result)")
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
            // The validation is manual, i.e. will be done outside the library, so only return the recipe
            finish(result: .success(ReceiptProductInfo(expiredInfo: [], receipt: receiptData)))
        case .apple:
            // Validation by accessing the Apple web service, for each product the subscription expiration date will be retrieved
            validationService.validateReceipt(receiptData) { [weak self] validationResult in
                guard let self = self else { return }
                
                switch validationResult {
                case let .success(json):
                    self.updateService.updateReceiptInfo(with: json) { infoFetchingResult in
                        switch infoFetchingResult {
                        case let .success(info):
                            self.finish(result: .success(ReceiptProductInfo(expiredInfo: info, receipt: receiptData)))
                        case let .failure(error):
                            #warning("May be return success with receipt only?")
                            self.finish(result: .failure(error))
                        }
                    }
                case let .failure(error):
                    self.finish(result: .failure(error))
                }
            }
        }
    }
    
    func finish(result: Result<ReceiptProductInfo, Error>) {
        completion?(result)
        completion = nil
    }
}
