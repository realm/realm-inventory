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
    let realm = try! Realm()

    override func viewDidAppear(_ animated: Bool) {
        loginViewController = LoginViewController(style: .lightOpaque)

        if let user = SyncUser.current {
            // yup - we've got a stored session, so just go right to the UITabView
            setDefaultRealmConfigurationWithUser(user: user, hostname: self.loginViewController.serverURL!)

            // We need to set global read/write for this top-level Realm; this can fail, and it's OK.
            setupDefaultGlobalPermissions(user: user, forURL: syncServerURL(hostname: self.loginViewController.serverURL!).absoluteString)

            let person = realm.object(ofType: Person.self, forPrimaryKey: user.identity!)
            if person == nil {
                try! realm.write {
                    realm.create(Person.self, value: ["id": user.identity!])
                }
            }

            performSegue(withIdentifier: "loginToMainView", sender: self)
            return
        }
        
        // show the RealmLoginKit controller
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

    func setupDefaultGlobalPermissions(user: SyncUser, forURL url: String) {
        user.apply(SyncPermission(realmPath: url, identity: "*", accessLevel: .write)) { error in
            if let error = error {
                print("Error: \(error)")
            }
            else {
                print("processed")
            }
        }
    }
}
