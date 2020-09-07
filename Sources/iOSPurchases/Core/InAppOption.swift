//
//  InAppOption.swift
//  Purchase
//
//  Created by Alexandr Nesterov on 4/29/19.
//  Copyright © 2019 Alexandr Nesterov. All rights reserved.
//

import Foundation
import StoreKit

public struct InAppOption {
    public let product: SKProduct
    public let formattedPrice: String
    
    init(product: SKProduct) {
        self.product = product
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.formatterBehavior = .behavior10_4
        formatter.locale = self.product.priceLocale
        formattedPrice = formatter.string(from: product.price) ?? "\(product.price)"
    }
}
