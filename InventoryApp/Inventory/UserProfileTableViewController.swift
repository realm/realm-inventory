////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 Realm Inc.
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
////////////////////////////////////////////////////////////////////////////


import UIKit
import QuartzCore

import RealmSwift
import ImagePicker
import Eureka
import ImageRow
import PermissionScope

class UserProfileViewController: FormViewController {
    var myIdentity = SyncUser.current?.identity!
    var thePersonRecord: Person?
    let realm = try! Realm()
    let pscope = PermissionScope()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        thePersonRecord = realm.objects(Person.self).filter(NSPredicate(format: "id = %@", myIdentity!)).first
        try! realm.write {
            if thePersonRecord == nil {
                thePersonRecord = realm.create(Person.self, value: ["id": myIdentity])
                realm.add(thePersonRecord!, update: true)
            }
        }
        
        
        form +++ Section(NSLocalizedString("Profile Information", comment: "Profile Information"))
            <<< ImageRow() { row in
                
                row.title = NSLocalizedString("Profile Image", comment: "profile image")
                row.sourceTypes = [.PhotoLibrary, .SavedPhotosAlbum, .Camera]
                row.clearAction = .yes(style: UIAlertActionStyle.destructive)
                }.cellSetup({ (cell, row) in
                    
                    if self.thePersonRecord!.avatar == nil {
                        row.value = UIImage(named: "Circled User Male_30")
                    } else {
                        let imageData = self.thePersonRecord?.avatar!
                        row.value = UIImage(data:imageData! as Data)!       //  this image row for Eureka seems to scale for us.  (was:  .scaleToSize(size: profileImage!.frame.size)  )
                    }
                }).onChange({ (row) in
                    try! self.realm.write {
                        if row.value != nil {
                            let resizedImage = row.value!.resizeImage(targetSize: CGSize(width: 128, height: 128))
                            self.thePersonRecord?.avatar = UIImagePNGRepresentation(resizedImage) as Data?
                        } else {
                            self.thePersonRecord?.avatar = nil
                            row.value = UIImage(named: "Circled User Male_30")
                        }
                    }
                })
            
            <<< TextRow(){ row in
                row.title = NSLocalizedString("First Name", comment:"First Name")
                row.placeholder = "First name"
                if self.thePersonRecord!.firstName != "" {
                    row.value = self.thePersonRecord!.firstName
                }
                }.onChange({ (row) in
                    try! self.realm.write {
                        if row.value != nil {
                            self.thePersonRecord!.firstName = row.value!
                            
                        } else {
                            self.thePersonRecord!.firstName = ""
                        }
                    }
                })
            <<< TextRow(){ row in
                row.title = NSLocalizedString("Last Name", comment:"Last name")
                row.placeholder = NSLocalizedString("Last name", comment: "Last Name")
                if self.thePersonRecord!.lastName != "" {
                    row.value = self.thePersonRecord!.lastName
                }
                }.onChange({ (row) in
                    try! self.realm.write {
                        if row.value != nil {
                            self.thePersonRecord!.lastName = row.value!
                        } else {
                            self.thePersonRecord!.lastName = ""
                        }
                    }
                })

        
        if self.thePersonRecord?.id == self.myIdentity! { // only makes sense to allow logout for ourselves
            form  +++ Section("Actions")
                <<< ButtonRow(){ row in
                    row.title = NSLocalizedString("Logout", comment: "")
                    }.onCellSelection({ (sectionName, rowName) in
                        self.handleLogoutPressed(sender: self)
                    })
        }
        
        pscope.viewControllerForAlerts = self
        pscope.headerLabel.text = NSLocalizedString("Permissions", comment: "Inventoruy Permissions")
        pscope.addPermission(CameraPermission(), message: NSLocalizedString("Used to add/edit your profile image", comment:"camera perms text"))
        pscope.addPermission(PhotosPermission(), message: NSLocalizedString("Used to pick a profile image", comment:"photo perms text"))

    }
    
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    // Actions
    
    @IBAction func handleLogoutPressed(sender: AnyObject) {
        let alert = UIAlertController(title: NSLocalizedString("Logout", comment: "Logout"), message: NSLocalizedString("Really Log Out?", comment: "Really Log Out?"), preferredStyle: .alert)
        
        // Logout button
        let OKAction = UIAlertAction(title: NSLocalizedString("Logout", comment: "logout"), style: .default) { (action:UIAlertAction!) in
            print("Logout button tapped");
            
            SyncUser.current?.logOut()
            //Now we need to segue to the login view controller
            self.performSegue(withIdentifier: "segueToLogin", sender: self)
        }
        alert.addAction(OKAction)
        
        // Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction!) in
            print("Cancel button tapped");
        }
        alert.addAction(cancelAction)
        
        // Present Dialog message
        present(alert, animated: true, completion:nil)
        
    }
        

    
}
