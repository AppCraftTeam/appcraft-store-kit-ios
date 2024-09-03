import Foundation
import StoreKit

open class ACReceiptProductRequest: NSObject {
    public typealias Completion = (Result<ACReceiptProductInfo, Error>) -> Void
    
    private let receiptService: ACReceiptService
    private let validationService: ACReceiptValidationService
    private let updateService: ACReceiptUpdateService
    
    private var completion: Completion?
    
    public init(sharedSecretKey: String, keyReceiptMaxExpiresDate: String) {
        self.receiptService = ACReceiptService()
        self.validationService = ACReceiptValidationService(sharedSecretKey: sharedSecretKey)
        self.updateService = ACReceiptUpdateService(keyReceiptMaxExpiresDate: keyReceiptMaxExpiresDate)
    }
    
    open func start(validationType: ACReceiptValidationType, _ completion: Completion?) {
        self.completion = completion
        print("fetchReceiptfetchReceipt start... validationType \(validationType)")

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

private extension ACReceiptProductRequest {
    
    func handleReceiptData(_ receiptData: Data, validationType: ACReceiptValidationType) {
        print("validationType - \(validationType)")
        switch validationType {
        case .manual:
            // The validation is manual, i.e. will be done outside the library, so only return the recipe
            finish(result: .success(ACReceiptProductInfo(expiredInfo: [], receipt: receiptData)))
        case .apple:
            // Validation by accessing the Apple web service, for each product the subscription expiration date will be retrieved
            validationService.validateReceipt(receiptData) { [weak self] validationResult in
                guard let self = self else { return }
                
                switch validationResult {
                case let .success(json):
                    print("validationResult success")
                    self.updateService.updateReceiptInfo(with: json) { infoFetchingResult in
                        print("validationResult infoFetchingResult - \(infoFetchingResult)")
                        switch infoFetchingResult {
                        case let .success(info):
                            self.finish(result: .success(ACReceiptProductInfo(expiredInfo: info, receipt: receiptData)))
                        case let .failure(error):
                            #warning("May be return success with receipt only?")
                            self.finish(result: .failure(error))
                        }
                    }
                case let .failure(error):
                    print("validationResult failure - \(error)")
                    self.finish(result: .failure(error))
                }
            }
        }
    }
    
    func finish(result: Result<ACReceiptProductInfo, Error>) {
        print("completion - \(completion)")
        completion?(result)
        //completion = nil
    }
}
