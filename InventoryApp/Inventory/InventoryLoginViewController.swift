//
//  InventoryLoginViewController.swift
//  Realm-Inventory
//
//  Created by David Spector on 1/23/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import UIKit
import RealmSwift
import RealmLoginKit

class InventoryLoginViewController: UIViewController {

    var loginViewController: LoginViewController!
    var token: NotificationToken!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        loginViewController = LoginViewController(style: .lightOpaque)

        if (SyncUser.current != nil) {
            // yup - we've got a stored session, so just go right to the UITabView
            setDefaultRealmConfigurationWithUser(user: SyncUser.current!, hostname: self.loginViewController.serverURL!)

            // We need to set global read/write for this top-level Realm; this can fail, and it's OK.
            setupDefaultGlobalPermissions(user: SyncUser.current, forURL: self.loginViewController.serverURL!)

            performSegue(withIdentifier: "loginToMainView", sender: self)
        } else {
            // show the RealmLoginKit controller
            //loginViewController = LoginViewController(style: .lightOpaque)
            if loginViewController!.serverURL == nil {
                loginViewController!.serverURL = defaultSyncHost
            }
            // Set a closure that will be called on successful login
            loginViewController.loginSuccessfulHandler = { user in
                DispatchQueue.main.async {
                    setDefaultRealmConfigurationWithUser(user: SyncUser.current!, hostname: self.loginViewController.serverURL!)
                    self.loginViewController!.dismiss(animated: true, completion: nil)
                    self.performSegue(withIdentifier: "loginToMainView", sender: nil)
                }
            }
            
            present(loginViewController, animated: true, completion: nil)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func setupDefaultGlobalPermissions(user: SyncUser?, forURL url: String) {
        
        let managementRealm = try! user!.managementRealm()
        let theURL = url
        
        let permissionChange = SyncPermissionChange(realmURL: theURL,    // The remote Realm URL on which to apply the changes
            userID: "*",       // The user ID for which these permission changes should be applied
            mayRead: true,     // Grant read access
            mayWrite: true,    // Grant write access
            mayManage: false)  // Grant management access
        
        token = managementRealm.objects(SyncPermissionChange.self).filter("id = %@", permissionChange.id).addNotificationBlock { notification in
            if case .update(let changes, _, _, _) = notification, let change = changes.first {
                // Object Server processed the permission change operation
                switch change.status {
                case .notProcessed:
                    print("not processed.")
                case .success:
                    print("succeeded.")
                case .error:
                    print("Error.")
                }
                print("change notification: \(change.debugDescription)")
            }
        }
        
        try! managementRealm.write {
            print("Launching permission change request id: \(permissionChange.id)")
            managementRealm.add(permissionChange)
        }
    }
    

    


    // MARK: - Navigation

}
