//
//  String + Localized.swift
//  Purchase
//
//  Created by Alexandr Nesterov on 4/30/19.
//  Copyright © 2019 Alexandr Nesterov. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        let budnle = Bundle(for: Purchase.self)
        return budnle.localizedString(forKey: self, value: self, table: "PurchaseLocalizable")
    }
}
