//
//  FlatMateShoppingListItem.swift
//  FlatMate
//
//  Created by Jamie Walker on 8/08/19.
//  Copyright © 2019 Jamie Walker. All rights reserved.

import Foundation
import SwiftyJSON

class FMShoppingListItem {
    
    // ================================
    // Variables
    // ================================
    
    var itemId: String?
    var description: String?
    var checkedOff: Bool?
    
    var session: FMSession?
    
    // ================================
    // Functions
    // ================================
    
    /*
     Create a shopping list item with API JSON data
     
     - Parameters:
        - fromItemJSON: the database JSON
        - session: the parent session
     */
    init(fromItemJSON: JSON, session: FMSession) {
        self.session = session
        
        itemId = fromItemJSON["itemId"].stringValue
        description = fromItemJSON["itemName"].stringValue
        checkedOff = fromItemJSON["completed"].stringValue == "1"
    }
    
    /*
     Sets the item's checked off status
     
     - Parameters:
        - checked: the checked status to set
     
     - Completion:
        - Sets the checked off status of the FMShoppingListItem
        - Parameter:
            - success, true if successfully set, false otherwise
     */
    func setCheckedOff(checked: Bool, completion: @escaping (Bool) -> ()) {
        let DG = DispatchGroup()
        
        var databaseCompleted: String?
        if checked { databaseCompleted = "1" } else { databaseCompleted = "0" }
        
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/shoppingItemCompleted/\(self.itemId ?? "0")/\(databaseCompleted!)/\(self.session?.flat?.flatId ?? "")&token=\(self.session?.token ?? "")"
        
        // Perform query
        var statusCode: Int?
        
        DG.enter()
        query.doPut(url: url, body: nil) { (_, i) in
            // Get the data from the query
            statusCode = i
            DG.leave()
        }
        
        // Process the response
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                self.checkedOff = checked
                completion(true)
            }
        }
    }
    
    /*
     Sets the item's description
     
     - Completion:
        - Sets the description of the FMShoppingListItem
        - Parameter:
            - success, true if successfully set, false otherwise
     */
    func updateItemDescription(completion: @escaping (Bool)->()) {
        let DG = DispatchGroup()
        
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/shoppingItemName/\(self.session?.flat?.flatId ?? "0")&token=\(self.session?.token ?? "")"
            
        let json = JSON(["itemId": self.itemId ?? "",
                         "itemName": self.description ?? ""])
        
        print(url)
        print(json.rawString()!)
        
        let body = json.rawString()!.data(using: .utf8)
        
        // Perform query
        var statusCode: Int?
        
        DG.enter()
        query.doPut(url: url, body: body) { (_, i) in
            // Get the data from the query
            statusCode = i
            DG.leave()
        }
        
        // Process the response
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}
