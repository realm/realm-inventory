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

import UIKit
import RealmSwift
import RealmLoginKit

class InventoryLoginViewController: UIViewController {

    var loginViewController: LoginViewController!
    var token: NotificationToken!
    var myIdentity = SyncUser.current?.identity!
    var thePersonRecord: Person?
    let realm = try! Realm()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        loginViewController = LoginViewController(style: .lightOpaque)

        if (SyncUser.current != nil) {
            // yup - we've got a stored session, so just go right to the UITabView
            setDefaultRealmConfigurationWithUser(user: SyncUser.current!, hostname: self.loginViewController.serverURL!)

            // We need to set global read/write for this top-level Realm; this can fail, and it's OK.
            setupDefaultGlobalPermissions(user: SyncUser.current, forURL: syncServerURL(hostname: self.loginViewController.serverURL!).absoluteString)

            let myIdentity = SyncUser.current?.identity!
            thePersonRecord = realm.objects(Person.self).filter(NSPredicate(format: "id = %@", myIdentity!)).first
            try! realm.write {
                if thePersonRecord == nil {
                    thePersonRecord = realm.create(Person.self, value: ["id": myIdentity])
                    realm.add(thePersonRecord!, update: true)
                }
            }
            

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
       // let theURL = url
        
        let permissionChange = SyncPermissionChange(realmURL: url,    // The remote Realm URL on which to apply the changes
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
