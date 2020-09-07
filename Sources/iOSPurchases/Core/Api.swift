//
//  Api.swift
//  Purchase
//
//  Created by Alexandr Nesterov on 4/29/19.
//  Copyright © 2019 Alexandr Nesterov. All rights reserved.
//

import Foundation

class Api {
    
    var url: URL!
    
    var urlString: String! {
        didSet {
            url = URL(string: urlString)!
        }
    }
    
    func verify(req: Request, completion: ((Response?, Error?) -> ())? = nil) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? req.jsonData()
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let session = URLSession(configuration: .default)
        session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion?(nil, error)
                return
            }
            if let data = data {
                do {
                    completion?(try Response(data: data), nil)
                } catch {
                    completion?(nil, error)
                }
            }
        }.resume()
    }
}
