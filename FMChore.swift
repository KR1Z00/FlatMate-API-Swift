//
//  FlatMateChore.swift
//  FlatMate
//
//  Created by Jamie Walker on 8/08/19.
//  Copyright © 2019 Jamie Walker. All rights reserved.

import Foundation
import SwiftyJSON

class FMChore {
    
    // ================================
    // Variables
    // ================================
    
    var choreId: String?
    var choreDescription: String?
    var userId: String?
    var flatId: String?
    var completed: Bool?
    var autoRotate: Bool?
    var rotateDays: String?
    var dateLastRotated: String?
    var nextRotateDay: String?
    
    var session: FMSession?
    
    // ================================
    // Functions
    // ================================
    
    /*
     Create a chore without API JSON data
     
     - Parameters:
        - session: the parent session
     */
    init(session: FMSession?) { self.session = session }
    
    /*
     Create a chore with API JSON data
     
     - Parameters:
        - fromChoreJSON: the database JSON
        - session: the parent session
     */
    init(fromChoreJSON: JSON, session: FMSession) {
        self.session = session
        
        choreId = fromChoreJSON["choreId"].stringValue
        choreDescription = fromChoreJSON["choreDescription"].stringValue
        userId = fromChoreJSON["userId"].stringValue
        flatId = fromChoreJSON["flatId"].stringValue
        autoRotate = fromChoreJSON["autoRotate"].stringValue == "1"
        rotateDays = fromChoreJSON["rotateDays"].stringValue
        completed = fromChoreJSON["completed"].stringValue == "1"
        dateLastRotated = fromChoreJSON["dateLastRotated"].stringValue
        nextRotateDay = fromChoreJSON["nextRotateDay"].stringValue
    }
    
    /*
     Gets the name of the user to do the chore to display
     
     - Returns:
        - name: "You" if the session user, firstName if a flatmate user
     */
    func userName() -> String? {
        if self.userId == session?.user?.userId {
            return "You"
        } else {
            let user = self.session?.flat?.flatMates.first(where: { (u) -> Bool in
                return u.userId == self.userId
            })
            
            return user?.firstName
        }
    }
    
    /*
     Updates the chore, replaces FMChore in flat with same choreId with new FMChore from database JSON data
     
     - Completion:
         - Replaces the chore in the flat with new chore from database JSON
             - Parameter:
             - success: true if successfully updated, false otherwise
     */
    func update(completion: @escaping (Bool)->()) {
        let DG = DispatchGroup()
        
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/updateChore&token=\(self.session?.token ?? "")"
        
        let body = databaseJSON().rawString()!.data(using: .utf8)!
        
        // Perform query
        var data: Data?
        var statusCode: Int?
        
        DG.enter()
        query.doPut(url: url, body: body) { (d, i) in
            // Get the data from the query
            data = d
            statusCode = i
            DG.leave()
        }
        
        // Process query response
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                let index = self.session?.flat?.chores.firstIndex(where: { (c) -> Bool in
                    return c.choreId == self.choreId
                })
                self.session?.flat?.chores.remove(at: index!)
                
                do {
                    let choreJSON = try JSON(data: data!)
                    let newChore = FMChore(fromChoreJSON: choreJSON, session: self.session!)
                    self.session?.flat?.chores.insert(newChore, at: index!)
                    self.session?.flat?.categoriseChores()
                    
                    completion(true)
                } catch {
                    completion(false)
                    return
                }
                
                
            }
        }
    }
    
    /*
     Updates the chore completed status
     
     - Completion:
        - Updates the chore completion status
        - Parameter:
            - success: true if successfully updated, false otherwise
     */
    func updateCompleted(completed: Bool, completion: @escaping (Bool)->()) {
        let DG = DispatchGroup()
        
        // Setup query
        let query = FMHTTPQuery()
        let url = "https://www.jamieleewalker.com/flatmate/api/updateChoreCompleted&token=\(self.session?.token ?? "")"
        
        let body = JSON(["choreId" : self.choreId ?? "",
                         "flatId" : self.flatId ?? "",
                         "completed" : completed ? "1" : "0"]).rawString()!.data(using: .utf8)!
        
        // Perform query
        var statusCode: Int?
        
        DG.enter()
        query.doPut(url: url, body: body) { (_, i) in
            // Get the data from the query
            statusCode = i
            DG.leave()
        }
        
        // Process response
        DG.notify(queue: .main) {
            if statusCode != 200 {
                completion(false)
            } else {
                self.completed = completed
                completion(true)
            }
        }
    }
    
    /*
     Creates a SwiftyJSON JSON object containing the chore information
     
     - Returns:
     - JSON object containing the chore information
     */
    func databaseJSON() -> JSON {
        return JSON(["choreId": self.choreId ?? "",
                     "description": self.choreDescription ?? "",
                     "userId": self.userId ?? "",
                     "flatId": self.session?.flat?.flatId ?? "",
                     "completed": (self.completed ?? false) ? "1": "0",
                     "autoRotate": (self.autoRotate ?? false) ? "1": "0",
                     "rotateDays": self.rotateDays ?? "",
                     "timeZone": TimeZone.current.identifier])
    }
}
