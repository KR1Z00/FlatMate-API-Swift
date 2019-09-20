//
//  FlatMateHTTPRequest.swift
//  FlatMate
//
//  Created by Jamie Walker on 8/08/19.
//  Copyright © 2019 Jamie Walker. All rights reserved.

import Foundation
import SwiftyJSON

class FMHTTPQuery {
    
    // ================================
    // Variables
    // ================================
    
    var DG = DispatchGroup()
    
    // ================================
    // Functions
    // ================================
    
    /*
     Performs an HTTP request
     
     - Parameters:
        - method: the HTTP request method - POST, GET, PUT, DELETE
        - url: the url to send the request to
        - body: the data to put in the request body
        - completion:
            - function to perform once the request has been completed
            - Parameters:
                - data: the data received from the HTTP request
                - statusCode: the statusCode received from the HTTP request
     */
    func doRequest(method: String, url: String, body: Data?, completion: @escaping (Data?, Int?) -> ()) {
        // Create the url
        let urlAsURL = URL(string: url)
        
        // Create the request
        var request = URLRequest(url: urlAsURL!)
        request.httpBody = body
        request.httpMethod = method
        request.addValue(TimeZone.current.identifier, forHTTPHeaderField: "timeZone")
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let r = response as? HTTPURLResponse {
                completion(data, r.statusCode)
            } else {
                // No connection
                completion(nil, -999)
            }
        }
        
        task.resume()
    }
    
    // Do a GET request
    func doGet(url: String, completion: @escaping (Data?, Int?) -> ()){
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        
        doRequest(method: "GET", url: url, body: nil) { (d, i) in
            data = d
            statusCode = i
            
            self.DG.leave()
        }
        
        DG.notify(queue: .main) {
            completion(data, statusCode)
        }
    }
    
    // Do a POST request
    func doPost(url: String, body: Data, completion: @escaping (Data?, Int?) -> ()){
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        
        doRequest(method: "POST", url: url, body: body) { (d, i) in
            data = d
            statusCode = i
            
            self.DG.leave()
        }
        
        DG.notify(queue: .main) {
            completion(data, statusCode)
        }
    }
    
    // Do an UPDATE request
    func doUpdate(url: String, body: Data, completion: @escaping (Data?, Int?) -> ()){
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        
        doRequest(method: "UPDATE", url: url, body: body) { (d, i) in
            data = d
            statusCode = i
            
            self.DG.leave()
        }
        
        DG.notify(queue: .main) {
            completion(data, statusCode)
        }
    }
    
    // Do a DELETE request
    func doDelete(url: String, body: Data?, completion: @escaping (Data?, Int?) -> ()){
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        
        doRequest(method: "DELETE", url: url, body: body) { (d, i) in
            data = d
            statusCode = i
            
            self.DG.leave()
        }
        
        DG.notify(queue: .main) {
            completion(data, statusCode)
        }
    }
    
    // Do a PUT request
    func doPut(url: String, body: Data?, completion: @escaping (Data?, Int?) -> ()){
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        
        doRequest(method: "PUT", url: url, body: body) { (d, i) in
            data = d
            statusCode = i
            
            self.DG.leave()
        }
        
        DG.notify(queue: .main) {
            completion(data, statusCode)
        }
    }
}

// Extension for dates for use with the database
extension Date {
    
    // Create a date from a database string **NOT INPUT FILTERED**
    init(fromDatabaseString: String) {
        let dateData = fromDatabaseString.split(separator: "-")
        let calendar = Calendar.current
        
        let dateComponents = DateComponents(calendar: calendar, year: Int(dateData[0]), month: Int(dateData[1]), day: Int(dateData[2]))
        self = calendar.date(from: dateComponents)!
    }
    
    // Get a database string representation of a date
    func asDatabaseString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self)
    }
    
    // Get a display string representation of a date
    func asDisplayString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.string(from: self)
    }
}
