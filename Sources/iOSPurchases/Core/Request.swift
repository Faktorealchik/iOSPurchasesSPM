//
//  Request.swift
//  Purchase
//
//  Created by Alexandr Nesterov on 5/10/19.
//  Copyright © 2019 Alexandr Nesterov. All rights reserved.
//

import Foundation

public struct Request: Codable {
    public let receipt: String
    public let key: String
}

extension Request {
    func jsonData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}
