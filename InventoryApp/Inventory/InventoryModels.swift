////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//////////////////////////////////////////////////////////////////////////////

import Foundation
import Realm
import RealmSwift


private var realm: Realm!

class Person : Object {
    dynamic var id = ""
    dynamic var creationDate: Date?
    dynamic var lastName = ""
    dynamic var firstName = ""
    dynamic var avatar : Data? // binary image data, stored as a PNG


    override static func primaryKey() -> String? {
        return "id"
    }

    
    func fullName() -> String {
        return "\(firstName) \(lastName)"
    }

}


class Product : Object {
    dynamic var id = ""                 // this should be something that's universal, like a UPC
    dynamic var creationDate: Date?
    dynamic var lastUpdated: Date?
    dynamic var productName = ""
    dynamic var productDescription = ""
    dynamic var image : Data? // binary image data, stored as a PNG
    var amount: Int {
        get {
            return self.quantityOnHand()
        }
    }
    // until the true counter properties are available we'll emulate
    // counters with a list (i.e., every addition or subtraction will be a list entry).
    // To find out the number of units on hand a sum of the list values is performed
    // conversely to find out the amount "sold" the absolute value of the sum of the negative
    // entries is returned
    
    let transactions = List<Transaction>()
    // Initializers, accessors & cet.
    override static func primaryKey() -> String? {
        return "id"
    }
    
    
    override static func ignoredProperties() -> [String] {
        return ["amount"]
    }

    /*
     * These versions use the map/reduce against agrregated collections - which is a valid way to 
     * do this computation. However Realm provides a set nice convenience methods built right 
     * into its collections, whihc is shown in the next set of functions
     */
    func quantityOnHandUsingMapReduce() -> Int {
        let realm = try! Realm()
        let transactions = realm.objects(Transaction.self).filter("productId = %@", self.id).map{$0.amount} // get all the amounts for the product as an array
        return transactions.reduce(0, +) // now sum them to get the QoH
    }

    func quantitySoldUsingMapReduce() -> Int {
        let realm = try! Realm()
        let transactions = realm.objects(Transaction.self).filter("productId = %@", self.id).map({$0.amount}).filter({$0 < 0}) // get only # sold (neg numbers) for the product
        return abs(transactions.reduce(0, +)) // now sum them (in this case the abs(sum of the reductions) to inventory) to get the qunat sold
    }
    

    /*
     * These versions use the inherent Realm aggregation functions
     */
    func quantitySold() -> Int {
        let realm = try! Realm()
        let transactions = realm.objects(Transaction.self).filter("productId = %@ AND amount < 0", self.id) // get only # sold (neg numbers) for the product
        return transactions.sum(ofProperty: "amount")
    }

    func quantityOnHand() -> Int {
        let realm = try! Realm()
        let transactions = realm.objects(Transaction.self).filter("productId = %@", self.id)
        return transactions.sum(ofProperty: "amount")
    }
    
    

    func addTransaction(quantity: Int, userIdentity: String) {
        let rlm = try! Realm()
        try! rlm.write {
            if quantity != 0 {
                let now = Date()
                let transaction = Transaction()
                transaction.transactionDate = now
                transaction.transactedBy = userIdentity
                transaction.productId = self.id
                transaction.amount = quantity
                rlm.add(transaction, update: true)
                
                self.lastUpdated = now
                self.transactions.append(transaction)
                rlm.add(self, update: true)
            }
            
        }

    }
    
    // this is used to allow us to know if we should allow editing of the main quant 
    // on hand item in the product edit view. If there is an existing history adding 
    // the number if skew the counts, so don't allow if it transactions have already 
    // started on this product
        func hasTransactionHistory() -> Bool {
        let realm = try! Realm()
        return realm.objects(Transaction.self).filter("productId = %@", self.id).count > 0
    }

    
    
    // @TODO - implement me!
    /**
     * get total quantity sold between the specified dates, or if only a start date, from the start date to the present
     * @returns The return value is an array of dictionaries representing the values for each date in the range.
     */
    func quantitySold(between startDate: Date, endDate: Date?) -> Array<Dictionary<Date, Int>>? {
        var rv = Array<Dictionary<Date, Int>>()
//        let realm = try! Realm()
//        var actualEndDate = Date()
//        var actualStartDate = startDate
//        
//        if endDate != nil {
//            actualEndDate = endDate!
//        }
//        if startDate > actualEndDate {
//            var tmpdate = actualEndDate
//            actualEndDate = startDate
//            actualStartDate = tmpdate
//        }
//        
//       We'd lke to do this: let dateRange = actualStartDate..<actualEndDate   ...but unfortunately a range is not sequence type, so instead,
//       we'll generate a sequence using NSCalendar types
//
//        // Impl notes:  need to calc days between dats to get number of final dicts we need to return
//        // then we need to aggregate arrays for inventory reduction (sell) transactions and sum them as above in quantity
//        for day in actualStartDate..<actualEndDate {
//
//        let transactions = realm.objects(Transaction.self).filter("productId = %@ AND transactionDate like %@", self.id, day).map({$0.amount}).filter({$0 < 0}) // get only # sold (neg numbers) for the product
//        let quantForDay =  abs(transactions.reduce(0, +)) // now sum them (in this case the abs(sum of the reductions) to inventory) to get the quantity sold
//         rv.append(Dictionary(day, quantForDay))
//        }
        
        return rv.count == 0 ? nil : rv
    }
    
    // NB: in a real inventory system one would account for "returns" which count against sales but not necessarily against 
    // inventory IFF the item is "unopened" and can be returned to stock.  If we decide tomake this into a true demo inventory system
    // we will have to add support for this and related stocking/restocking functions.
    
    
    
    /**
     * find out the qunatity added to the inventory between the two supplied dates, or if only a start date, from the start date to the present
     * @returns The return value is an array of dictionaries representing the values for each date in the range.
    */
    func quantityReplenished(between startDate: Date, endDate: Date) -> Array<Dictionary<Date, Int>>? {
        return nil
    }
    
}



class Transaction : Object {
    dynamic var id = NSUUID().uuidString    // every transaction is unique but the person doing it, the products and amounts, of course are not
    dynamic var transactionDate: Date?
    dynamic var transactedBy = ""           // a Realm SyncUser.identity
    dynamic var productId = ""              // the product this refers to
    dynamic var amount = 0                  // positive = inventory addition, negative == sale or inventory reduction
    
    // Initializers, accessors & cet.
    override static func primaryKey() -> String? {
        return "id"
    }
}


