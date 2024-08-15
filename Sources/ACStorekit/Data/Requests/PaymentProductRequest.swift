import Foundation
import StoreKit

open class PaymentProductRequest: NSObject {
    public typealias Completion = (SKPaymentTransaction?, Error?) -> Void
    
    private var completion: Completion?
    
    open func puschase(product: SKProduct, _ completion: Completion?) {
        guard self.completion == nil else { return }
        self.completion = completion

        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(.init(product: product))
    }
    
    open func restore(_ completion: Completion?) {
        guard self.completion == nil else { return }
        self.completion = completion
        
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    private func finish(result: SKPaymentTransaction?, error: Error?) {
        self.completion?(result, error)
        self.completion = nil
    }
}

extension PaymentProductRequest: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            
            case .purchased,
                 .restored:
                self.completion?(transaction, nil)
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                self.completion?(nil, transaction.error)
                SKPaymentQueue.default().finishTransaction(transaction)
            case .purchasing:
                break
            default:
                self.completion?(nil, nil)
                break
            }
        }
    }
}
