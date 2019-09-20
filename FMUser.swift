//
//  FlatMateUser.swift
//  FlatMate
//
//  Created by Jamie Walker on 8/08/19.
//  Copyright © 2019 Jamie Walker. All rights reserved.

import Foundation
import SwiftyJSON

class FMUser {
    
    // ================================
    // Variables
    // ================================
    
    var userId: String?
    var username: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    var password: String?
    
    var session: FMSession?
    
    // ================================
    // Functions
    // ================================
    
    /*
     Create a user from API JSON data
     
     - Parameters:
     - fromLoginJSON: the database login JSON
     - session: the parent session
     */
    init(_ fromLoginJSON: JSON, session: FMSession?) {
        userId = fromLoginJSON["userId"].string
        username = fromLoginJSON["username"].string
        firstName = fromLoginJSON["firstName"].string
        lastName = fromLoginJSON["lastName"].string
        email = fromLoginJSON["email"].string
        self.session = session
    }
    
    /*
     Create a user from API JSON data for a flatmate
     
     - Parameters:
     - fromLoginJSON: the database login JSON
     - session: the parent session
     */
    init(fromFlatMateJSON: JSON, session: FMSession?) {
        userId = fromFlatMateJSON["userId"].string
        username = fromFlatMateJSON["username"].string
        firstName = fromFlatMateJSON["firstName"].string
        lastName = fromFlatMateJSON["lastName"].string
        self.session = session
    }
    
    /*
     Updates the user's username
     
     - Parameters:
     - newUsername: the login username
     
     - Completion:
        - Updates the username
        - Parameter:
            - success: true for a successful update, false otherwise
     */
    func updateUsername(newUsername: String, completion: @escaping (Bool)->()) {
        let DG = DispatchGroup()
        
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/users/\(self.userId ?? "")/username&token=\(self.session?.token ?? "")"
        
        let json = JSON(["username" : newUsername])
        let body = json.rawString()!.data(using: .utf8)!
        
        // Perform query
        var statusCode: Int?
        
        DG.enter()
        query.doPut(url: url, body: body) { (_, i) in
            // Get the data from the query
            statusCode = i
            DG.leave()
        }
        
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                self.username = newUsername
                completion(true)
            }
        }
    }
    
    /*
     Updates the user's password
     
     - Parameters:
     - newPassword: the new password
     
     - Completion:
        - Updates the password
        - Parameter:
            - success: true for a successful update, false otherwise
     */
    func updatePassword(newPassword: String, completion: @escaping (Bool)->()) {
        let DG = DispatchGroup()
        
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/users/\(self.userId ?? "")/password&token=\(self.session?.token ?? "")"
        
        let json = JSON(["password" : newPassword])
        let body = json.rawString()!.data(using: .utf8)!
        
        // Perform query
        var statusCode: Int?
        
        DG.enter()
        query.doPut(url: url, body: body) { (_, i) in
            // Get the data from the query
            statusCode = i
            DG.leave()
        }
        
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                self.password = newPassword
                completion(true)
            }
        }
    }
    
    /*
     Updates the user's email
     
     - Parameters:
     - newEmail: the new email
     
     - Completion:
        - Updates the email
        - Parameter:
            - success: true for a successful update, false otherwise
     */
    func updateEmail(newEmail: String, completion: @escaping (Bool)->()) {
        let DG = DispatchGroup()
        
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/users/\(self.userId ?? "")/email&token=\(self.session?.token ?? "")"
        
        let json = JSON(["email" : newEmail])
        let body = json.rawString()!.data(using: .utf8)!
        
        // Perform query
        var statusCode: Int?
        
        DG.enter()
        query.doPut(url: url, body: body) { (_, i) in
            // Get the data from the query
            statusCode = i
            DG.leave()
        }
        
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                self.email = newEmail
                completion(true)
            }
        }
    }
    
    /*
     Updates the user's first name
     
     - Parameters:
     - newFirstName: the new first name
     
     - Completion:
        - Updates the first name
        - Parameter:
            - success: true for a successful update, false otherwise
     */
    func updateFirstName(newFirstName: String, completion: @escaping (Bool)->()) {
        let DG = DispatchGroup()
        
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/users/\(self.userId ?? "")/firstName&token=\(self.session?.token ?? "")"
        
        let json = JSON(["firstName" : newFirstName])
        let body = json.rawString()!.data(using: .utf8)!
        
        // Perform query
        var statusCode: Int?
        
        DG.enter()
        query.doPut(url: url, body: body) { (_, i) in
            // Get the data from the query
            statusCode = i
            DG.leave()
        }
        
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                self.firstName = newFirstName
                completion(true)
            }
        }
    }
    
    /*
     Updates the user's last name
     
     - Parameters:
     - newLastName: the new last name
     
     - Completion:
        - Updates the last name
        - Parameter:
            - success: true for a successful update, false otherwise
     */
    func updateLastName(newLastName: String, completion: @escaping (Bool)->()) {
        let DG = DispatchGroup()
        
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/users/\(self.userId ?? "")/lastName&token=\(self.session?.token ?? "")"
        
        let json = JSON(["lastName" : newLastName])
        let body = json.rawString()!.data(using: .utf8)!
        
        // Perform query
        var statusCode: Int?
        
        DG.enter()
        query.doPut(url: url, body: body) { (_, i) in
            // Get the data from the query
            statusCode = i
            DG.leave()
        }
        
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                self.lastName = newLastName
                completion(true)
            }
        }
    }
}
