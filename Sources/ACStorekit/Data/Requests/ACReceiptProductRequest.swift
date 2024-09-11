import Foundation
import StoreKit

/// `ACReceiptProductRequest` is responsible for fetching and validating a receipt
open class ACReceiptProductRequest: NSObject {
    
    /// Typealias for the completion handler
    public typealias Completion = (Result<ACReceiptProductInfo, Error>) -> Void
    
    /// Service responsible for fetching the receipt data
    private let receiptService: ACReceiptService
    
    /// Service responsible for validating the receipt
    private let validationService: ACReceiptValidationService
    
    /// Service responsible for updating the receipt with expiration information
    private let updateService: ACReceiptUpdateService
    
    /// The level of logging
    private var logLevel: ACLogLevel
    
    /// The completion handler that will be called when the process is finished
    private var completion: Completion?
    
    /// Initializes the `ACReceiptProductRequest`
    /// - Parameters:
    ///   - sharedSecretKey: The shared secret key used for validating receipts with Apple
    ///   - keyReceiptMaxExpiresDate: A key used to fetch the max expiration date of the receipt
    ///   - logLevel: The level of logging
    public init(sharedSecretKey: String, keyReceiptMaxExpiresDate: String, logLevel: ACLogLevel) {
        self.receiptService = ACReceiptService(logLevel: logLevel)
        self.validationService = ACReceiptValidationService(sharedSecretKey: sharedSecretKey)
        self.updateService = ACReceiptUpdateService(keyReceiptMaxExpiresDate: keyReceiptMaxExpiresDate, logLevel: logLevel)
        self.logLevel = logLevel
    }
    
    /// Starts the receipt request process, fetching and validating the receipt
    /// - Parameters:
    ///   - validationType: The type of receipt validation
    ///   - completion: Completion handler that returns the result of the receipt request
    open func start(validationType: ACReceiptValidationType, _ completion: Completion?) {
        self.completion = completion
        if self.logLevel == .full {
            print("[ACReceiptProductRequest] start with validationType: \(validationType)")
        }
        
        // Fetch the receipt using the receipt service
        receiptService.fetchReceipt { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .success(receiptData):
                if self.logLevel == .full {
                    print("[ACReceiptProductRequest] fetchReceipt succeeded")
                }
                // Proceed to handle the fetched receipt data based on the validation type
                self.handleReceiptData(receiptData, validationType: validationType)
            case let .failure(error):
                if self.logLevel.isAllowPrintError {
                    print("[ACReceiptProductRequest] fetchReceipt error: \(error)")
                }
                // Handle any errors during the receipt fetching process
                self.completion?(.failure(error))
            }
        }
    }
    
    /// Retrieves the raw receipt data if available.
    open func getReceiptData() -> Data? {
        receiptService.receiptData
    }
}

private extension ACReceiptProductRequest {
    
    /// Handles the fetched receipt data
    /// - Parameters:
    ///   - receiptData: The raw receipt data to handle
    ///   - validationType: The type of validation
    func handleReceiptData(_ receiptData: Data, validationType: ACReceiptValidationType) {
        if self.logLevel == .full {
            print("[ACReceiptProductRequest] validate receipt via \(validationType) started")
        }
        
        switch validationType {
        case .manual:
            // The validation is manual, i.e. will be done outside the library, so only return the recipe
            if self.logLevel == .full {
                print("[ACReceiptProductRequest] skipping validation for manual mode")
            }
            completion?(.success(ACReceiptProductInfo(expiredInfo: [], receipt: receiptData)))
            
        case .apple:
            // Validation by accessing the Apple web service, for each product the subscription expiration date will be retrieved
            if self.logLevel == .full {
                print("[ACReceiptProductRequest] validating receipt via Apple started")
            }
            validationService.validateReceipt(receiptData) { [weak self] validationResult in
                guard let self = self else { return }
                
                switch validationResult {
                case let .success(json):
                    if self.logLevel == .full {
                        print("[ACReceiptProductRequest] receipt validation via Apple succeeded")
                    }
                    // Update the receipt information with expiration data from Apple
                    self.updateService.updateReceiptInfo(with: json) { infoFetchingResult in
                        switch infoFetchingResult {
                        case let .success(info):
                            if self.logLevel == .full {
                                print("[ACReceiptProductRequest] receipt info update succeeded")
                            }
                            self.completion?(.success(ACReceiptProductInfo(expiredInfo: info, receipt: receiptData)))
                        case let .failure(error):
                            if self.logLevel.isAllowPrintError {
                                print("[ACReceiptProductRequest] failed to update receipt info, error: \(error)")
                            }
                            self.completion?(.failure(error))
                        }
                    }
                case let .failure(error):
                    if self.logLevel.isAllowPrintError {
                        print("[ACReceiptProductRequest] receipt validation via Apple failed, error: \(error)")
                    }
                    self.completion?(.failure(error))
                }
            }
        }
    }
}
