import Foundation
import StoreKit

open class ACPaymentProductRequest: NSObject {
    public typealias Completion = (Result<SKPaymentTransaction, Error>) -> Void
    
    private var completion: Completion?
    
    open func purchase(product: SKProduct, _ completion: Completion?) {
        self.completion = completion
        
        let paymentQueue = SKPaymentQueue.default()
        paymentQueue.add(self)
        paymentQueue.add(SKPayment(product: product))
    }
    
    open func restore(_ completion: Completion?) {
        self.completion = completion
        
        let paymentQueue = SKPaymentQueue.default()
        paymentQueue.add(self)
        paymentQueue.restoreCompletedTransactions()
    }
}

extension ACPaymentProductRequest: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                finish(result: .success(transaction))
            case .failed:
                if let error = transaction.error {
                    finish(result: .failure(error))
                } else {
                    finish(result: .failure(NSError(domain: "UnknownError", code: -1, userInfo: nil)))
                }
            default:
                break
            }
            
            if transaction.transactionState != .purchasing {
                SKPaymentQueue.default().finishTransaction(transaction)
            }
        }
    }
}

private extension ACPaymentProductRequest {
    
    func finish(result: Result<SKPaymentTransaction, Error>) {
        completion?(result)
        
        SKPaymentQueue.default().remove(self)
    }
}
