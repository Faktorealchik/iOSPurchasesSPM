//
//  Response.swift
//  Purchase
//
//  Created by Alexandr Nesterov on 4/29/19.
//  Copyright © 2019 Alexandr Nesterov. All rights reserved.
//

import Foundation

public struct Response: Decodable {
    public let isSubscribed: Bool
    public let dateEnd: Int64?
    public let serverDate: Int64?
    
    public var date: Date {
        return Date(timeIntervalSince1970: Double(dateEnd ?? 0))
    }
    
    public var server: Date {
        return Date(timeIntervalSince1970: Double(serverDate ?? 0))
    }
    
    init(data: Data) throws {
        self = try JSONDecoder().decode(Response.self, from: data)
    }
}
