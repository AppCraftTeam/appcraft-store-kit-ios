//
//  PurchaseStoreKitService.swift
//
//
//  Created by Pavel Moslienko on 22.07.2024.
//

import Foundation
import StoreKit

@available(iOS 15.0, *)
@MainActor
class SubscriptionsManager: NSObject, ObservableObject {
    let productIDs: [String]
    var purchasedProductIDs: Set<String> = []
    
    @Published var products: [Product] = []
    
    private var updates: Task<Void, Never>? = nil
    
    override init(productIDs: [String]) {
        self.productIDs = productIDs
        super.init()
        self.updates = observeTransactionUpdates()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        updates?.cancel()
    }
    
    func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                await self.updatePurchasedProducts()
            }
        }
    }
}

@available(iOS 15.0, *)
extension SubscriptionsManager {
    func loadProducts() async {
        do {
            self.products = try await Product.products(for: productIDs)
                .sorted(by: { $0.price > $1.price })
            print("products - \(self.products)")
        } catch {
            print("Failed to fetch products")
        }
    }
    
    func buyProduct(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case let .success(.verified(transaction)):
                // Successful purhcase
                await transaction.finish()
                await self.updatePurchasedProducts()
            case let .success(.unverified(_, error)):
                print("Unverified purchase. Error: \(error)")
                break
            case .pending:
                // Transaction waiting on SCA (Strong Customer Authentication) or pproval from Ask to Buy
                break
            case .userCancelled:
                print("User cancelled")
                break
            @unknown default:
                print("Failed to purchase the product")
                break
            }
        } catch {
            print("Failed to purchase the product")
        }
    }
    
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            print(error)
        }
    }
}

@available(iOS 15.0, *)
extension SubscriptionsManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
}
