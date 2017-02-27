//
//  RealmUtils.swift
//  Inventory
//
//  Created by David Spector on 2/23/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

let defaultSyncHost                 = "127.0.0.1"
let syncRealmPath                   = "InventoryDemo"


let kKoginToMainView                = "loginToMainView"
let kExitToLoginViewSegue           = "segueToLogin"
let kInventoryToProductDetail       = "inventoryToProductDetail"
let kInventoryToNewProduct          = "inventoryToNewProduct"
let kSortingPopoverSegue            = "SortByPopover"


func syncServerURL(hostname: String) -> URL {
    return  URL(string: "realm://\(hostname):9080/\(syncRealmPath)")!
}

func syncAuthURL(hostName: String) -> URL {
    return  URL(string: "http://\(hostName):9080")!
}

func setDefaultRealmConfigurationWithUser(user: SyncUser, hostname: String) {
    Realm.Configuration.defaultConfiguration = Realm.Configuration(
        syncConfiguration: SyncConfiguration(user: user, realmURL:syncServerURL(hostname: hostname) ),
        objectTypes: [Product.self, Transaction.self, Person.self]
    )
}

