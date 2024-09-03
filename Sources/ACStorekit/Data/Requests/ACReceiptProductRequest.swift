import Foundation
import StoreKit

open class ACReceiptProductRequest: NSObject {
    public typealias Completion = (Result<ACReceiptProductInfo, Error>) -> Void
    
    private let receiptService: ACReceiptService
    private let validationService: ACReceiptValidationService
    private let updateService: ACReceiptUpdateService
    private var logLevel: ACLogLevel

    private var completion: Completion?
    
    public init(sharedSecretKey: String, keyReceiptMaxExpiresDate: String, logLevel: ACLogLevel) {
        self.receiptService = ACReceiptService(logLevel: logLevel)
        self.validationService = ACReceiptValidationService(sharedSecretKey: sharedSecretKey)
        self.updateService = ACReceiptUpdateService(keyReceiptMaxExpiresDate: keyReceiptMaxExpiresDate, logLevel: logLevel)
        self.logLevel = logLevel
    }
    
    open func start(validationType: ACReceiptValidationType, _ completion: Completion?) {
        self.completion = completion
        if self.logLevel == .full {
            print("[ACReceiptProductRequest] start with validationType: \(validationType)")
        }

        receiptService.fetchReceipt { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(receiptData):
                if self.logLevel == .full {
                    print("[ACReceiptProductRequest] fetchReceipt successed")
                }
                self.handleReceiptData(receiptData, validationType: validationType)
            case let .failure(error):
                if self.logLevel.isAllowPrintError {
                    print("[ACReceiptProductRequest] fetchReceipt error: \(error)")
                }
                self.completion?(.failure(error))
            }
        }
    }
    
    open func getReceiptData() -> Data? {
        receiptService.receiptData
    }
}

private extension ACReceiptProductRequest {
    
    func handleReceiptData(_ receiptData: Data, validationType: ACReceiptValidationType) {
        if self.logLevel == .full {
            print("[ACReceiptProductRequest] validate receipt via apple successed")
        }
        switch validationType {
        case .manual:
            // The validation is manual, i.e. will be done outside the library, so only return the recipe
            if self.logLevel == .full {
                print("[ACReceiptProductRequest] skip validation for manual")
            }
            completion?(.success(ACReceiptProductInfo(expiredInfo: [], receipt: receiptData)))
        case .apple:
            // Validation by accessing the Apple web service, for each product the subscription expiration date will be retrieved
            if self.logLevel == .full {
                print("[ACReceiptProductRequest] validate receipt via apple started")
            }
            validationService.validateReceipt(receiptData) { [weak self] validationResult in
                guard let self = self else { return }
                
                switch validationResult {
                case let .success(json):
                    if self.logLevel == .full {
                        print("[ACReceiptProductRequest] validate receipt via apple successed")
                    }
                    self.updateService.updateReceiptInfo(with: json) { infoFetchingResult in
                        switch infoFetchingResult {
                        case let .success(info):
                            if self.logLevel == .full {
                                print("[ACReceiptProductRequest] update receipt info successed")
                            }
                            self.completion?(.success(ACReceiptProductInfo(expiredInfo: info, receipt: receiptData)))
                        case let .failure(error):
                            #warning("May be return success with receipt only?")
                            if self.logLevel.isAllowPrintError {
                                print("[ACReceiptProductRequest] update receipt info failed, error: \(error)")
                            }
                            self.completion?(.failure(error))
                        }
                    }
                case let .failure(error):
                    if self.logLevel.isAllowPrintError {
                        print("[ACReceiptProductRequest] validate receipt via apple failed, error: \(error)")
                    }
                    self.completion?(.failure(error))
                }
            }
        }
    }
}
