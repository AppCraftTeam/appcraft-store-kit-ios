import Foundation
import StoreKit

/// `ACPaymentProductRequest` is responsible for handling in-app purchases and restoring purchases
open class ACPaymentProductRequest: NSObject {
    
    /// Typealias for the completion handler
    public typealias Completion = (Result<SKPaymentTransaction, Error>) -> Void
    
    /// The completion handler that will be invoked when a transaction is finished
    private var completion: Completion?
    
    /// Purchase product
    /// - Parameters:
    ///   - product: The `SKProduct` to purchase.
    ///   - completion: A completion handler that returns the result of the payment.
    open func purchase(product: SKProduct, _ completion: Completion?) {
        self.completion = completion
        
        let paymentQueue = SKPaymentQueue.default()
        paymentQueue.add(self)
        paymentQueue.add(SKPayment(product: product))
    }
    
    /// Restores purchases
    /// - Parameters:
    ///   - completion: A completion handler that returns the result of the restore purchases.
    open func restore(_ completion: Completion?) {
        self.completion = completion
        
        let paymentQueue = SKPaymentQueue.default()
        paymentQueue.add(self)
        paymentQueue.restoreCompletedTransactions()
    }
}

// MARK: - SKPaymentTransactionObserver
extension ACPaymentProductRequest: SKPaymentTransactionObserver {
    
    /// Called when the payment queue updates one or more transactions
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                // The transaction was successfully purchased or restored.
                finish(result: .success(transaction))
            case .failed:
                // The transaction failed
                if let error = transaction.error {
                    finish(result: .failure(error))
                } else {
                    finish(result: .failure(NSError(domain: "UnknownError", code: -1, userInfo: nil)))
                }
            default:
                break
            }
            
            // If the transaction is not in the "purchasing" state, mark it as finished.
            if transaction.transactionState != .purchasing {
                SKPaymentQueue.default().finishTransaction(transaction)
            }
        }
    }
}

private extension ACPaymentProductRequest {
    
    /// Finish the transaction
    func finish(result: Result<SKPaymentTransaction, Error>) {
        completion?(result)
        
        // Remove the current instance as an observer from the payment queue.
        SKPaymentQueue.default().remove(self)
    }
}
