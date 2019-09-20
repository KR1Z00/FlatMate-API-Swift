//
//  FlatMatePayment.swift
//  FlatMate
//
//  Created by Jamie Walker on 8/08/19.
//  Copyright © 2019 Jamie Walker. All rights reserved.

import Foundation
import SwiftyJSON

class FMPayment {
    
    // ================================
    // Variables
    // ================================
    
    var paymentId: String?
    var dueDate: Date?
    var description: String?
    var amount: Double?
    var currency: String?
    var paid: Bool?
    var split: Bool?
    
    var session: FMSession?
    
    // ================================
    // Functions
    // ================================
    
    /*
     Create a payment without API JSON data
     
     - Parameters:
        - session: the parent session
     */
    init(session: FMSession) { self.session = session }
    
    /*
     Create a payment with API JSON data
     
     - Parameters:
        - fromPaymentJSON: the database JSON
        - session: the parent session
     */
    init(fromPaymentJSON: JSON, session: FMSession) {
        self.session = session
        
        paymentId = fromPaymentJSON["paymentId"].stringValue
        dueDate = Date(fromDatabaseString: fromPaymentJSON["dueDate"].stringValue)
        description = fromPaymentJSON["description"].stringValue
        amount = Double(fromPaymentJSON["amount"].stringValue)
        currency = fromPaymentJSON["currency"].stringValue
        paid = fromPaymentJSON["paid"].stringValue == "1"
        split = fromPaymentJSON["split"].stringValue == "1"
    }
    
    /*
     Updates the payment, replaces FMPayment in flat with same paymentId with new FMPayment from database JSON data
     
     - Completion:
        - Replaces the payment in the flat with new payment from database JSON
        - Parameter:
            - success: true if successfully updated, false otherwise
     */
    func update(completion: @escaping (Bool)->()) {
        let DG = DispatchGroup()
        
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/updatePayment/\(session?.flat?.flatId ?? "")&token=\(self.session?.token ?? "")"
        
        let jsonString = databaseJSON()
        let body = jsonString.rawString()!.data(using: .utf8)!
        
        // Perform query
        var statusCode: Int?
        
        DG.enter()
        query.doPut(url: url, body: body) { (_, i) in
            // Get the data from the query
            statusCode = i
            DG.leave()
        }
        
        // Process the query data
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                // Replace the payment in flat with self with same paymentId
                let index = self.session?.flat?.payments.firstIndex(where: { (p) -> Bool in return p.paymentId == self.paymentId })
                self.session?.flat?.payments.remove(at: index!)
                let newPayment = FMPayment(fromPaymentJSON: jsonString, session: self.session!)
                self.session?.flat?.payments.insert(newPayment, at: index!)
                self.session?.flat?.categorisePayments()
                
                completion(true)
            }
        }
    }
    
    /*
     Creates a SwiftJSON JSON object with self's data
     
     - Returns:
     - json: SwiftyJSON object with self's data for database query
     */
    func databaseJSON() -> JSON {
        // Get data
        let dueDate = self.dueDate?.asDatabaseString()
        let description = self.description ?? ""
        let amount = String(self.amount ?? 0)
        let currency = self.currency ?? "Dollars"
        var paid: String?
        var split: String?
        
        if (self.paid ?? false) { paid = "1" } else { paid = "0" }
        if (self.split ?? false) { split = "1" } else { split = "0" }
        
        // Create JSON with data
        let json = JSON(["paymentId": self.paymentId ?? "",
                         "userId": self.session?.user?.userId ?? "",
                         "dueDate": dueDate,
                         "description": description,
                         "amount": amount,
                         "currency": currency,
                         "paid": paid,
                         "split": split])
        
        return json
    }
    
    /*
     Formats the payment amount for display
     
     - Returns:
        - amount string: divided by number of flatmates if split is true, formatted to 2dp
     */
    func amountString() -> String {
        var a = amount
        
        if self.split == true {
            let nFlatmates = (session?.flat?.flatMates.count)! + 1
            a = a! / Double(nFlatmates)
        }
        
        return String(format: "%.2f", a ?? 0)
    }
    
    /*
     Gets the display format due date
     
     - Returns:
        - String: get the due date as a display string
     */
    func dateString() -> String {
        return self.dueDate?.asDisplayString() ?? "01/01/2000"
    }
    
}
