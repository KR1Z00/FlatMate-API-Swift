//
//  FlatMateSession.swift
//  FlatMate
//
//  Created by Jamie Walker on 8/08/19.
//  Copyright © 2019 Jamie Walker. All rights reserved.

import Foundation
import SwiftyJSON

class FMSession {
    
    // ================================
    // Variables
    // ================================
    
    var user: FMUser?
    var flat: FMFlat?
    var token: String?
    
    var DG = DispatchGroup()
    
    // ================================
    // Functions
    // ================================
    
    init() { }
    
    /*
     Logs a user in
     
     - Parameters:
        - username: the login username
        - password: the login password
     
     - Completion:
        - Processes the api data recieved (self.processSessionData())
        - Parameter:
            - success: true for a successful login, false otherwise
     */
    func login(username: String, password: String, completion: @escaping (Bool) -> ()){
        // Setup login query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/login"
        let json = JSON(["username": username, "password": password, "timeZone": TimeZone.current.identifier])
        let body = json.rawString()!.data(using: .utf8)!
        
        // Perform query
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        query.doPost(url: url, body: body) { (d, i) in
            // Get the data from the query
            data = d
            statusCode = i
            self.DG.leave()
        }
        
        DG.notify(queue: .main) {
            let success = self.processSessionData(data: data, statusCode: statusCode, password: password)
            completion(success)
        }
    }
    
    /*
     Logs a user in
     
     - Parameter:
        - registerData: [email, username, password, firstName, lastName] register data for API
     
     - Completion:
        - Processes the api data recieved (self.processSessionData())
        - Parameter:
            - success: true for a successful register, false otherwise
     */
    func register(registerData: [String], completion: @escaping (Bool) -> ()) {
        // Setup register query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/register"
        let json = JSON(["email": registerData[0], "username": registerData[1], "password": registerData[2], "firstName": registerData[3], "lastName": registerData[4]])
        let body = json.rawString()!.data(using: .utf8)!
        
        // Perform query
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        query.doPost(url: url, body: body) { (d, i) in
            // Get the data from the query
            data = d
            statusCode = i
            self.DG.leave()
        }
        
        DG.notify(queue: .main) {
            let result = self.processSessionData(data: data, statusCode: statusCode, password: registerData[2])
            completion(result)
        }
    }
    
    /*
     Adds a payment to the flat
     
     - Parameters:
        - paymentData: [userId, flatId, dueDate, description, amount, currency, paid, split]
     
     - Completion:
        - Adds the new payment to the flat
        - Parameter:
            - success: true if succesfully added, false otherwise
     */
    func addPayment(paymentData: [String], completion: @escaping (Bool)->()) {
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/payment&token=\(self.token ?? "")"
        
        // Create the JSON data
        let json = JSON(["userId": self.user?.userId ?? "",
                         "flatId": self.flat?.flatId ?? "",
                         "dueDate": paymentData[0],
                         "description": paymentData[1],
                         "amount": paymentData[2],
                         "currency": paymentData[3],
                         "paid": paymentData[4],
                         "split": paymentData[5]])
        
        let body = json.rawString()!.data(using: .utf8)!
        
        // Perform query
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        query.doPost(url: url, body: body) { (d, i) in
            // Get the data from the query
            data = d
            statusCode = i
            self.DG.leave()
        }
        
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                // Create JSON From data
                var paymentJSON: JSON?
                
                do {
                    paymentJSON = try JSON(data: data!)
                    paymentJSON = try paymentJSON!.merged(with: json)
                } catch {
                    completion(false)
                    return
                }
                
                // Add new payment to the flat
                let payment = FMPayment(fromPaymentJSON: paymentJSON!, session: self)
                self.flat?.payments.append(payment)
                self.flat?.categorisePayments()
                
                completion(true)
            }
        }
    }
    
    /*
     Deletes a payment from the flat
     
     - Parameters:
        - paymentId: the ID of the payment to delete
     
     - Completion:
        - Deletes the payment from the flat
        - Parameter:
            - success: true if payment is successfully deleted, false otherwise
     */
    func deletePayment(paymentId: Int, completion: @escaping (Bool)->()) {
        // Setup the API call
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/payment/\((self.user?.userId)!)/\(paymentId)&token=\(token ?? "")"
        
        var statusCode: Int?
        
        // Perform the query
        DG.enter()
        query.doDelete(url: url, body: nil) { (_, i) in
            statusCode = i
            self.DG.leave()
        }
        
        // Process the query result
        DG.notify(queue: .main) {
            if statusCode == 200 {
                self.flat?.payments.removeAll(where: { (p) -> Bool in
                    p.paymentId == "\(paymentId)"
                })
                self.flat?.categorisePayments()
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    /*
     Joins a flat code
     
        - Parameters:
            - flatCode: the flat code to join
     
        - Completion:
            - Processes the api data recieved (self.processSessionData())
            - Parameter:
                - success: true if successfully joined, false otherwise
     */
    func joinFlatCode(flatCode: String, completion: @escaping (Bool) -> ()) {
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/joinFlat/\(user?.userId ?? "0")/\(flatCode)&token=\(token ?? "")"
        
        // Perform query
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        query.doPut(url: url, body: nil) { (d, i) in
            // Get the data from the query
            data = d
            statusCode = i
            self.DG.leave()
        }
        
        // Process the session data recieved
        DG.notify(queue: .main) {
            if statusCode == 200 {
                let result = self.processSessionData(data: data, statusCode: statusCode, password: self.user!.password!)
                completion(result)
            } else {
                completion(false)
            }
        }
    }
    
    /*
     Creates a new flat
     
     - Completion:
        - Processes the api data recieved (self.processSessionData())
        - Parameter:
            - success: true if successfully created, false otherwise
     */
    func createFlat(completion: @escaping (Bool) -> ()) {
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/createFlat/\(user?.userId ?? "0")&token=\(token ?? "")"
        
        print(url)
        
        // Perform query
        var data: Data?
        var statusCode: Int?
        
        // Perform query
        DG.enter()
        query.doPut(url: url, body: nil) { (d, i) in
            // Get the data from the query
            data = d
            statusCode = i
            self.DG.leave()
        }
        
        // Process the data recieved
        DG.notify(queue: .main) {
            if statusCode == 200 {
                let result = self.processSessionData(data: data, statusCode: statusCode, password: self.user!.password!)
                completion(result)
            }
        }
    }
    
    /*
     Processes the data from a FMHTTPQuery for the session
     
        - Parameters:
            - data: the data from the query
            - statusCode: the HTTP status code
     
        - Returns:
            - success: true if successfully processed data, false otherwise
     */
    func processSessionData(data: Data?, statusCode: Int?, password: String) -> Bool {
        // Process the data
        if data == nil {
            return false
        }
        else if statusCode != 200 {
            return false
        }
        else {
            // Parse the JSON
            var resultJSON: JSON?
            do { resultJSON = try JSON(data: data!) } catch {
                return false
            }
            
            // Set the user and flat
            let userJSON = resultJSON!["user"]
            let flatJSON = resultJSON!["flat"]
            
            // Check if user if null
            if let _ = userJSON.null {
                return false
            } else {
                self.user = FMUser(userJSON, session: self)
                self.user?.password = password
            }
            
            // Check if the flat is null
            if let _ = flatJSON.null {
                self.flat = nil
            } else {
                self.flat = FMFlat(flatJSON, session: self)
            }
            
            // Save the API token
            self.token = resultJSON!["token"].string
            
            return true
        }
    }
    
    /*
     Removes a flatmate from the flat
     
        - Parameters:
            - flatMateUserId: the userId of the flatmate to remove
     
        - Completion:
            - success: true if successfully removed, false otherwise
     */
    func removeFlatMate(flatMateUserId: String, completion: @escaping (Bool) -> ()) {
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/flatUserRelationship/\(flatMateUserId)/\(self.flat?.flatId ?? "0")?token=\(self.token ?? "")"
        
        // Perform query
        var statusCode: Int?
        
        DG.enter()
        query.doDelete(url: url, body: nil) { (_, i) in
            statusCode = i
            self.DG.leave()
        }
        
        // Proccess query data
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
                return
            } else {
                self.flat?.flatMates.removeAll(where: { (user) -> Bool in
                    return user.userId == flatMateUserId
                })
                completion(true)
            }
        }
    }
    
    /*
     Leaves the current flat
     
     - Completion:
        - Removes the flat from the session
        - Parameter:
            - success: true if successfully left the flat, false otherwise
     */
    func leaveFlat(completion: @escaping (Bool) -> ()) {
        // Setup login query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/flatUserRelationship/\(self.user?.userId ?? "0")/\(self.flat?.flatId ?? "0")?token=\(self.token ?? "")"
        
        // Perform query
        var statusCode: Int?
        
        DG.enter()
        query.doDelete(url: url, body: nil) { (_, i) in
            statusCode = i
            self.DG.leave()
        }
        
        // Set the flat to nil
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                self.flat = nil
                completion(true)
            }
        }
    }
    
    /*
     Adds a shopping list item to the flat
     
     - Parameters:
        - description: the shopping list item description
     
     - Completion:
        - Adds the item to the shopping list
        - Parameter:
            - success: true if successfully added, false otherwise
     */
    func addShoppingItem(description: String, completion: @escaping ()->()) {
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/shoppingItem&token=\(self.token ?? "")"
        
        let json = JSON(["flatId": self.flat?.flatId ?? "0",
                         "description": description])
        
        let body = json.rawString()!.data(using: .utf8)!
        
        // Perform query
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        query.doPost(url: url, body: body) { (d, i) in
            // Get the data from the query
            data = d
            statusCode = i
            self.DG.leave()
        }
        
        // Proccess the query data
        DG.notify(queue: .main) {
            if statusCode == 200 {
                let itemJSON = JSON(data!)
                let item = FMShoppingListItem(fromItemJSON: itemJSON, session: self)
                self.flat?.shoppingList.append(item)
            }
            
            completion()
        }
    }
    
    /*
     Deletes the completed shopping list items from the list
     
     - Completion:
        - Refreshes the shopping list with only unselected items
        - Parameter:
            - success: true if successfully deleted items, false otherwise
     */
    func deleteCompletedShoppingItems(completion: @escaping ()->()) {
        // Setup the API call
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/completedShoppingListItems/\(self.flat?.flatId ?? "0")&token=\(token ?? "")"
        
        var statusCode: Int?
        var data: Data?
        
        // Perform the query
        DG.enter()
        query.doDelete(url: url, body: nil) { (d, i) in
            data = d
            statusCode = i
            self.DG.leave()
        }
        
        // Process the data
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion()
                return
            }
            
            // Refresh the shopping list
            self.flat?.shoppingList.removeAll()
            
            let itemsJSON = JSON(data!).arrayValue
            for itemJSON in itemsJSON {
                let shoppingListItem = FMShoppingListItem(fromItemJSON: itemJSON, session: self)
                self.flat!.shoppingList.append(shoppingListItem)
            }
            
            completion()
        }
    }

    /*
     Gets the FMUser object of a flatmate based off a userId
     
     - Parameters:
        - fromUserId: the userId of the flatmate to select
     
     - Returns:
        - The FMUser object of the corresponding userId
     */
    func getFlatMate(fromUserId: String?) -> FMUser? {
        if fromUserId == self.user?.userId {
            return self.user!
        } else {
            for fm in (self.flat?.flatMates)! {
                if fm.userId == fromUserId {
                    return fm
                }
            }
        }
        
        return nil
    }
    
    /*
     Get all the flatmates in the flat
     
     - Returns:
        - toReturn: an array of all flatmates in the flat including the user
     */
    func getAllFlatMates() -> [FMUser] {
        var toReturn = [self.user!]
        toReturn.append(contentsOf: self.flat!.flatMates)
        
        return toReturn
    }
    
    /*
     Adds a chore to the flat
     
     - Parameters:
        - chore: the FMChore object to add to the flat
     
     - Completion:
        - Adds a new chore to the flat based off the user input
     */
    func addChore(chore: FMChore, completion: @escaping ()->()) {
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/chore&token=\(self.token ?? "")"
        
        let body = chore.databaseJSON().rawString()!.data(using: .utf8)!
        
        // Perform query
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        query.doPost(url: url, body: body) { (d, i) in
            // Get the data from the query
            data = d
            statusCode = i
            self.DG.leave()
        }
        
        // Process the API data recieved
        DG.notify(queue: .main) {
            if statusCode == 200 {
                let choreJSON = JSON(data!)
                let chore = FMChore(fromChoreJSON: choreJSON, session: self)
                self.flat?.chores.append(chore)
                self.flat?.categoriseChores()
            }
            
            completion()
        }
    }

    /*
     Deletes a chore from the flat
     
     - Parameters:
        - choreId: the ID of the chore to remove
     
     - Completion:
        - Deletes the chore from the flat
        - Parameter:
            - success: true if successfully deleted, false otherwise
     */
    func deleteChore(choreId: String, completion: @escaping (Bool)->()) {
        // Setup the query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/chore/\((self.flat?.flatId)!)/\(choreId)&token=\(token ?? "")"
        
        var statusCode: Int?
        
        // Perform the query
        DG.enter()
        query.doDelete(url: url, body: nil) { (_, i) in
            statusCode = i
            self.DG.leave()
        }
        
        // Delete the chore
        DG.notify(queue: .main) {
            if statusCode == 200 {
                self.flat?.chores.removeAll(where: { (c) -> Bool in
                    c.choreId == choreId
                })
                self.flat?.categoriseChores()
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    /*
     Adds a flatmate to the flat without a user. Basically a placeholder flatmate
     
     - Parameters:
        - firstName: the first name of the flatmate
        - lastName: the last name of the flatmate
     
     - Completion:
        - Adds the FMUser of the flatmate to the flat
        -  Parameter:
            - success: true if successfully added, false otherwise
     */
    func addFlatmate(firstName: String, lastName: String, completion: @escaping (Bool)->()) {
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/flats/\(self.flat?.flatId ?? "")/users&token=\(self.token ?? "")"
        
        let json = JSON(["mode" : "noAccount",
                         "firstName" : firstName,
                         "lastName"  : lastName])
        
        let jsonString = json.rawString()!
        let body = jsonString.data(using: .utf8)!
        
        // Perform query
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        query.doPost(url: url, body: body) { (d, i) in
            // Get the data from the query
            data = d
            statusCode = i
            self.DG.leave()
        }
        
        // Process the query data
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                // Create JSON From data
                do {
                    let userJSON = try JSON(data: data!)
                    let flatMate = FMUser(fromFlatMateJSON: userJSON, session: self)
                    self.flat?.flatMates.append(flatMate)
                    
                    completion(true)
                } catch {
                    completion(false)
                    return
                }
            }
        }
    }
}
