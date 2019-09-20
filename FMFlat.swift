//
//  FlatMateFlat.swift
//  FlatMate
//
//  Created by Jamie Walker on 8/08/19.
//  Copyright © 2019 Jamie Walker. All rights reserved.

import Foundation
import SwiftyJSON

class FMFlat {
    
    // ================================
    // Variables
    // ================================
    
    var flatId: String?
    var flatCode: String?
    
    var flatMates: [FMUser] = []
    
    var shoppingList: [FMShoppingListItem] = []
    
    var payments: [FMPayment] = []
    var paidPayments: [FMPayment] = []
    var unpaidPayments: [FMPayment] = []
    var overduePayments: [FMPayment] = []
    
    var chores: [FMChore] = []
    var yourChores: [FMChore] = []
    var flatmateChores: [FMChore] = []
    var completedChores: [FMChore] = []
    var incompleteChores: [FMChore] = []
    
    var session: FMSession?
    
    // ================================
    // Functions
    // ================================
    
    /*
     Create a flat from API JSON data
     
     - Parameters:
        - fromJSON: the database JSON
        - session: the parent session
     */
    init(_ fromJSON: JSON, session: FMSession) {
        self.session = session
        
        // Load flat information
        self.flatId = fromJSON["flatId"].stringValue
        self.flatCode = fromJSON["flatCode"].stringValue
        
        // Load extra categories
        let flatMatesJSON = fromJSON["flatMates"].arrayValue
        let shoppingListJSON = fromJSON["shoppingList"].arrayValue
        let paymentsJSON = fromJSON["payments"].arrayValue
        let choresJSON = fromJSON["chores"].arrayValue
        
        // Load flatmates
        for flatMateJSON in flatMatesJSON {
            let flatMate = FMUser(fromFlatMateJSON: flatMateJSON, session: self.session)
            flatMates.append(flatMate)
        }
        
        // Load shopping list
        for shoppingListItemJSON in shoppingListJSON {
            let shoppingListItem = FMShoppingListItem(fromItemJSON: shoppingListItemJSON, session: session)
            shoppingList.append(shoppingListItem)
        }
        
        // Load payments
        for paymentJSON in paymentsJSON {
            let payment = FMPayment(fromPaymentJSON: paymentJSON, session: session)
            payments.append(payment)
        }
        
        // Load chores
        for choreJSON in choresJSON {
            let chore = FMChore(fromChoreJSON: choreJSON, session: self.session!)
            chores.append(chore)
        }
        
        // Categorise chores and payments
        categoriseChores()
        categorisePayments()
    }
    
    /*
     Categorises the chores into the categories:
        - Your chores, the user's chores
        - Flatmate chores, chores that aren't the user's
        - Completed chores, user's chores that are completed
        - Incomplete chores, user's chores that aren't completed
     */
    func categoriseChores() {
        // Reset arrays
        self.yourChores = [FMChore]()
        self.flatmateChores = [FMChore]()
        self.completedChores = [FMChore]()
        self.incompleteChores = [FMChore]()
        
        // Categorise between your chores and flatmate chores
        for c in self.chores {
            if c.userId == self.session?.user?.userId {
                self.yourChores.append(c)
            } else {
                self.flatmateChores.append(c)
            }
        }
        
        // Categorise between completed chores and incomplete chores
        for c in self.yourChores {
            if c.completed == true {
                self.completedChores.append(c)
            } else {
                self.incompleteChores.append(c)
            }
        }
    }
    
    /*
     Categorises the payments into the categories:
         - Paid payments
         - Unpaid payments
         - Overdue payments
     */
    func categorisePayments() {
        // Refresh the arrays
        self.paidPayments = [FMPayment]()
        self.unpaidPayments = [FMPayment]()
        self.overduePayments = [FMPayment]()
        
        // Categorise the chores
        for p in self.payments {
            if p.paid ?? false {
                self.paidPayments.append(p)
            } else {
                let today = Date(timeIntervalSinceNow: 0)
                if p.dueDate! < today {
                    overduePayments.append(p)
                } else {
                    unpaidPayments.append(p)
                }
            }
        }
    }
    
    /*
     Generates a new join code for the flat
     
     Completion:
        - Updates the join code
        - Parameter:
            - success: true if successfully updated, false otherwise
     */
    func generateNewJoinCode(completion: @escaping (Bool)->()) {
        let DG = DispatchGroup()
        
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/flats/\(self.flatId ?? "")/flatCode&token=\(self.session?.token ?? "")"
        
        // Perform query
        var statusCode: Int?
        var data: Data?
        
        DG.enter()
        query.doPut(url: url, body: nil) { (d, i) in
            // Get the data from the query
            statusCode = i
            data = d
            DG.leave()
        }
        
        // Process the query data
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                do {
                    let dataJSON = try JSON(data: data!)
                    let newCode = dataJSON["newCode"].stringValue
                    self.flatCode = newCode
                    completion(true)
                } catch {
                    completion(false)
                    return
                }
            }
        }
    }
}
