//
//  ProductDetailViewController.swift
//  Inventory
//
//  Created by David Spector on 2/24/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import UIKit
import Eureka
import ImageRow
import RealmSwift
import BRYXBanner


extension String {
    func currencyToString(value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale(identifier: Locale.current.identifier)
        let result = formatter.string(from: value as NSNumber)
        return result!
    }
    
    func numberToLocalString(value: Double, formatAsInteger: Bool = false, fractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = formatAsInteger ? 0 : fractionDigits
        formatter.locale = Locale(identifier: Locale.current.identifier)
        let result = formatter.string(from: value as NSNumber)
        return result!
    }
    
}


class ProductDetailViewController: FormViewController {

    let realm = try! Realm()
    var newProductMode = false
    var editMode = false
    var productId : String?
    var product: Product?
    var quantityTmp = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if newProductMode {
            let leftButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .plain, target: self, action: #selector(BackCancelPressed) as Selector?)
            let rightButton = UIBarButtonItem(title: NSLocalizedString("Save", comment: "Save"), style: .plain, target: self, action: #selector(SavePressed))
            self.navigationItem.leftBarButtonItem = leftButton
            self.navigationItem.rightBarButtonItem = rightButton

            
            product = Product()
            if productId != nil {
                product?.id = productId!
            }
        }
        else {
            product = realm.objects(Product.self).filter("id = %@", productId!).first
            let rightButton = UIBarButtonItem(title: NSLocalizedString("Edit", comment: "Edit"), style: .plain, target: self, action: #selector(EditTaskPressed))
            self.navigationItem.rightBarButtonItem = rightButton

        }

        
        if self.newProductMode == false {
            // if the redcord already exitrs, we need a stepper row in order to add or remove items in as transaction
        }

        // Do any additional setup after loading the view.
       form = createForm(editable: formIsEditable(), product: product)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: Form Utilities
    func createForm(editable: Bool, product: Product?) -> Form {
        
        let form = Form()
            form +++ Section(NSLocalizedString("Product Detail Information", comment: "Product Detail Information"))
            <<< TextRow(NSLocalizedString("Product ID", comment:"Product ID")) { row in
                row.title = NSLocalizedString("Product ID", comment:"Product ID")
                row.tag = "Product ID"
                if self.product!.id != "" {
                    row.value = self.product!.id
                }
                if editable == false {
                    row.disabled = true
                }
                }.cellSetup { cell, row in
                    cell.textField.placeholder = NSLocalizedString("(Enter UPC code)", comment:"Enter UPC code")
                }.onChange({ (row) in
                    self.product?.id = row.value!
                })
            
            <<< ImageRow() { row in
                row.title = NSLocalizedString("Profile Image", comment: "profile image")
                row.sourceTypes = [.PhotoLibrary, .SavedPhotosAlbum, .Camera]
                row.clearAction = .yes(style: UIAlertActionStyle.destructive)
                if editable == false {
                    row.disabled = true
                }

                }.cellSetup({ (cell, row) in
                    
                    if self.product!.image == nil {
                        row.value = UIImage(named: "Package")?.imageWithTint(tintColor: .lightGray)
                    } else {
                        let imageData = self.product?.image!
                        row.value = UIImage(data:imageData! as Data)!
                    }
                }).onChange({ (row) in
                    try! self.realm.write {
                        if row.value != nil {
                            let resizedImage = row.value!.resizeImage(targetSize: CGSize(width: 128, height: 128))
                            self.product?.image = UIImagePNGRepresentation(resizedImage) as Data?
                        } else {
                            self.product?.image = nil
                            row.value = UIImage(named: "Package")?.imageWithTint(tintColor: .lightGray)
                        }
                    }
                })
            
            <<< TextRow(){ row in
                row.title = NSLocalizedString("Product Name", comment:"Product Name")
                row.placeholder = "Acme RoadRunner Food"
                if self.product!.productName != "" {
                    row.value = self.product!.productName
                }
                if editable == false {
                    row.disabled = true
                }
                }.onChange({ (row) in
                    self.product?.productName = row.value!
                })
            
            <<< TextRow(){ row in
                row.value = self.product?.productDescription
                row.placeholder = NSLocalizedString("Product Description", comment: "description")
                if editable == false {
                    row.disabled = true
                }
                }.onChange({ (row) in
                    self.product?.productDescription = row.value!
                })
            
                <<< IntRow(){ row in
                    row.tag = "QuantityOnHandRow"
                    if self.newProductMode == true {
                        row.title = NSLocalizedString("Initial Quantity", comment:"Initial Quantity on Hand")
                        row.placeholder = NSLocalizedString("initial quantity", comment: "initial quantity")
                    } else {
                        row.title = NSLocalizedString("Quantity on Hand", comment:"Quantity on Hand")
                        row.placeholder = NSLocalizedString("No stock", comment: "initial quantity")
                    }
                    if editable == false || self.product!.hasTransactionHistory() == true { // if there's a transaction history, don't allow editing of QoH
                        row.disabled = true
                    }
                    }.cellUpdate({ (cell , row) in
                        row.value = self.product!.quantityOnHand()
                        row.reload()
                    })
                    .onChange({ (row) in
                        self.quantityTmp  = row.value!
                    })
                
                +++ Section(NSLocalizedString("Inventory Change Transaction", comment: "Inventory Change"))
                <<< StepperRow("Add or Subtract Items") { row in
                    row.tag = "quantityStepper"
                    row.title = NSLocalizedString("Add/Subtract", comment: "Add/Subtract")
                    }.cellSetup({ (cell, row) in
                        cell.stepper.minimumValue = -(Double)(UINT64_MAX)
                    })
                    .onChange({ (row) in
                        let actionButtonRow = form.rowBy(tag: "AddRemoveButton") as! ButtonRow
                        let qohRow = form.rowBy(tag: "QuantityOnHandRow") as! IntRow
                        
                        if row.value! < 0 {
                            actionButtonRow.disabled = false
                            actionButtonRow.title = NSLocalizedString("Subtract Quantity", comment: "Add")
                        } else if row.value! == 0{
                            actionButtonRow.disabled = true
                            actionButtonRow.title = NSLocalizedString("", comment: "Add")
                        } else if row.value! > 0 {
                            actionButtonRow.disabled = true
                            actionButtonRow.title = NSLocalizedString("Add Quantity", comment: "Add")
                        }
                        // However if we're removing items and the result of the requested change would be more 
                        // would be more than the quantity on hand (QoH), clamp the value at the QoH
                        if  row.value! < 0 && (Int(qohRow.value!) - abs(Int(row.value!)) < 0) {
                            row.value! = Double(qohRow.value!) * -1
                        }
                        
                        actionButtonRow.updateCell()
                    })
                <<< ButtonRow() { row in
                    row.tag = "AddRemoveButton"
                    row.title = ""
                    }.onCellSelection({ (cell, row)  in
                        let stepper = form.rowBy(tag: "quantityStepper") as! StepperRow
                        let qohRow = form.rowBy(tag: "QuantityOnHandRow") as! IntRow

                        if stepper.value != 0 { // belt & suspenders check - don't want zero-value transactions
                            self.product!.addTransaction(quantity: Int(stepper.value!), userIdentity: SyncUser.current!.identity!) // push the transaction
                            let banner = Banner(title: "Inventory Update Successful", subtitle: "Registered change of \(Int(stepper.value!)) item(s).", image: UIImage(named: "Icon"), backgroundColor: UIColor(red:48.00/255.0, green:174.0/255.0, blue:51.5/255.0, alpha:1.000))
                            banner.dismissesOnTap = true
                            banner.show(duration: 3.0)
                            stepper.value = 0
                            stepper.updateCell() // forces the stepper to update to zero
                            qohRow.updateCell() // forces the quantity on Hand to redisplay
                            
                        }
                    })
        return form
    }
    
    
    
    func formIsEditable() -> Bool {
        if newProductMode || editMode {
            return true
        }
        return false
    }

    // MARK: Actions
    @IBAction func BackCancelPressed(sender: AnyObject) {
        // Unwind/pop from the segue
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func EditTaskPressed(sender: AnyObject) {
        print("Edit Tasks Pressed")
        if editMode == true {
            //we're here becuase the user clicked edit (which now says "save") ... so we're going to save the record with whatever they've changed
            self.SavePressed(sender: self)
            editMode = false
        } else {
            self.navigationItem.rightBarButtonItem?.title = NSLocalizedString("Save", comment: "Save")
            editMode = true
            
            form = createForm(editable: formIsEditable(), product: product)
        }
    }
    
    
    
    @IBAction func SavePressed(sender: AnyObject) {

        let rlm = try! Realm()
        try! rlm.write {
            if self.newProductMode {
                self.product?.creationDate = Date()
                self.product?.lastUpdated = Date()
            } else {
                self.product?.lastUpdated = Date()
            }
            rlm.add(self.product!, update: true)
            if self.newProductMode == true && self.quantityTmp > 0 {
                self.product?.addTransaction(quantity: self.quantityTmp, userIdentity: SyncUser.current!.identity!)
                //let transaction = Transaction()
                //transaction.transactionDate = Date()
                //transaction.transactedBy = SyncUser.current!.identity!
                //transaction.productId = self.product!.id
                //transaction.amount = self.quantityTmp
                //rlm.add(transaction, update: true)
            }
            
        }
        // Unwind/pop from the segue
       _ = self.navigationController?.popViewController(animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
