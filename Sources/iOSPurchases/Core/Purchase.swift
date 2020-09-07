//
//  Purchase.swift
//  Purchase
//
//  Created by Alexandr Nesterov on 4/29/19.
//  Copyright © 2019 Alexandr Nesterov. All rights reserved.
//

import Foundation
import StoreKit

public class Purchase: NSObject {
    public static let shared = Purchase()
    
    public var serverUrlString: String! {
        didSet {
            api.urlString = serverUrlString
        }
    }
    public var serverUrl: URL! {
        didSet {
            api.url = serverUrl
        }
    }
    
    let api: Api
    
    private override init(){
        api = Api()
    }
    
    public static let optionsLoadedNotification = Notification.Name("InAppServiceOptionsLoadedNotification")
    public static let restoreSuccessfulNotification = Notification.Name("InAppServiceRestoreSuccessfulNotification")
    public static let purchaseSuccessfulNotification = Notification.Name("InAppServicePurchaseSuccessfulNotification")
    public static let filedNotification = Notification.Name("InAppServiceFailedNotification")
    public static let restoreFailed = Notification.Name("InAppServiceFailedNotification")
    public static let optionsFailedToLoad = Notification.Name("optionsFailedToLoad")
    
    var appKey: String!
    
    public var receipt: Data? {
        guard let url = Bundle.main.appStoreReceiptURL else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            print("Error loading receipt data: \(error.localizedDescription)")
            return nil
        }
    }
    
    public var onAddStorePayment: ((SKPayment) -> (Bool))?
    public var onUpdateTransactions: ((SKPaymentQueue, [SKPaymentTransaction]) -> ())? = nil
    public var options: [InAppOption]? {
        didSet {
            NotificationCenter.default.post(name: Purchase.optionsLoadedNotification, object: nil)
        }
    }
    
    public func start(key: String,
                      shouldAddStorePayment: ((SKPayment) -> (Bool))? = nil,
                      onUpdateTransactions: ((SKPaymentQueue, [SKPaymentTransaction]) -> ())? = nil) {
        appKey = key
        onAddStorePayment = shouldAddStorePayment
        self.onUpdateTransactions = onUpdateTransactions
        
        SKPaymentQueue.default().add(self)
    }
    
    public func load(inAppOptions: [String]) {
        let request = SKProductsRequest(productIdentifiers: Set(inAppOptions))
        request.delegate = self
        request.start()
    }
    
    public func purchase(option: InAppOption) {
        SKPaymentQueue.default().add(SKPayment(product: option.product))
    }
    
    public func restore(needVerifyInstantly: Bool = false, verifyingCompletion: ((Response?, Error?) -> ())? = nil) {
        SKPaymentQueue.default().restoreCompletedTransactions()
        
        if needVerifyInstantly {
            verify(completion: verifyingCompletion)
        }
    }
    
    public func isSubscribed(completion: @escaping (Bool, Error?) -> ()) {
        verify { (response, error) in
            if let error = error {
                completion(false, error)
                return
            }
            if let isSubscribed = response?.isSubscribed {
                completion(isSubscribed, nil)
                return
            }
            completion(false, NSError(domain: "purchase", code: 1, userInfo: ["error": "can not find response"]))
        }
    }
    
    public func verify(completion: ((Response?, Error?) -> ())? = nil) {
        api.verify(req: Request(receipt: receipt?.base64EncodedString() ?? "", key: appKey), completion: completion)
    }
    
    public func applicationWillTerminate() {
        SKPaymentQueue.default().remove(self)
    }
}

extension Purchase: SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest,
                                didReceive response: SKProductsResponse) {
        options = response.products.map {
            InAppOption(product: $0)
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        NotificationCenter.default.post(
            name: Purchase.optionsFailedToLoad,
            object: nil,
            userInfo: [
                "error": error,
                "description": description(from: error)
            ]
        )
    }
    
    func description(from: Error?) -> String {
        if let error = from as? SKError {
            switch error.code {
                case .cloudServicePermissionDenied: return "denied".localized
                case .cloudServiceRevoked: return "revoked".localized
                case .invalidOfferIdentifier: return "invalid id".localized
                case .invalidOfferPrice: return "invalid price".localized
                case .invalidSignature: return "invalid signature".localized
                case .missingOfferParams: return "missing params".localized
                case .paymentCancelled: return "cancelled".localized
                case .paymentInvalid: return "invalid".localized
                case .paymentNotAllowed: return "not allowed".localized
                case .privacyAcknowledgementRequired: return "privacy required".localized
                case .storeProductNotAvailable: return "not available".localized
                case .unauthorizedRequestData: return "unauth".localized
                case .unknown: return "unknown".localized
                case .clientInvalid: return "client invalid".localized
                case .cloudServiceNetworkConnectionFailed: return "service failed".localized
            @unknown default: return "unknown".localized
            }
        }
        return "unknown".localized
    }
}

extension Purchase: SKPaymentTransactionObserver {
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        handleRestoredState()
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        NotificationCenter.default.post(name: Purchase.restoreFailed, object: nil, userInfo: ["error": error])
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing: handlePurchasingState(for: transaction, in: queue)
            case .purchased: handlePurchasedState(transaction: transaction, in: queue)
            case .restored: queue.finishTransaction(transaction)
            case .failed: handleFailedState(for: transaction, in: queue)
            case .deferred: handleDeferredState(for: transaction, in: queue)
            @unknown default: break
            }
        }
        onUpdateTransactions?(queue, transactions)
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue,
                             shouldAddStorePayment payment: SKPayment,
                             for product: SKProduct) -> Bool {
        if let completion = onAddStorePayment {
            return completion(payment)
        }
        return false
    }
    
    func handlePurchasingState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        
    }
    
    func handlePurchasedState(transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        queue.finishTransaction(transaction)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Purchase.purchaseSuccessfulNotification, object: nil)
        }
    }
    
    func handleRestoredState() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Purchase.restoreSuccessfulNotification, object: nil)
        }
    }
    
    func handleFailedState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        let error = transaction.error
        let description = self.description(from: error)
        
        queue.finishTransaction(transaction)
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Purchase.filedNotification,
                object: nil,
                userInfo: ["error": error as Any,
                           "description": description])
        }
    }
    
    func handleDeferredState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        
    }
}
