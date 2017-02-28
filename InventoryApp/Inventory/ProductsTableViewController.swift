//
//  ViewController.swift
//  Inventory
//
//  Created by David Spector on 2/22/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import BarcodeScanner

class ProductsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate, SortOptionsSelectionProtocol {
    
    // Realm specific
    var realm = try! Realm()
    var notificationToken: NotificationToken? = nil
    let myIdentity = SyncUser.current?.identity!
    
    var products: Results<Product>?
    var sortProperty = "productName"
    var sortAscending = true
    var sortDirectionButtonItem: UIBarButtonItem!
    var searchBar:UISearchBar = UISearchBar()
    
    // this is realized if the user scans a unknown product & asnwers 'yes' 
    // to create new product based on it; we then segue using the newProduct path
    // and pass this in to prime the new product details page
    var newProductID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        sortDirectionButtonItem = self.navigationItem.leftBarButtonItems![1]
        sortDirectionButtonItem!.action = #selector(toggleSortDirection)
        sortDirectionButtonItem.title = self.sortAscending ? "↑" : "↓"
        
        
        searchBar.delegate = self
        searchBar.searchBarStyle = .prominent
        searchBar.placeholder = NSLocalizedString("Search...", comment: " Search...")
        searchBar.sizeToFit()
        searchBar.isTranslucent = false
        searchBar.backgroundImage = UIImage()
        navigationItem.titleView = searchBar
        
        products = realm.objects(Product.self).sorted(byKeyPath: sortProperty, ascending: sortAscending ? true : false)

        // Here's the important bit about how easy it is to deal with remote data in Realm:
        // Realm supports notifications that fire whenever data changes in a Realm you are watching;
        // In this case we're watching for changes our Products, we can implement it like this:
        
        notificationToken = products?.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            switch changes {
            case .initial:
                // Results are now populated and can be accessed without blocking the UI
                tableView.reloadData()
                break
            case .update(_, let deletions, let insertions, let modifications):
                // Query results have changed, so apply them to the UITableView
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0)}),
                                     with: .automatic)
                tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }),
                                     with: .automatic)
                tableView.endUpdates()
                break
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
                break
            }
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: true)
        }
        self.restortEntries()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products?.count ?? 0
    }
    
    override  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120.0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let product = products![indexPath.row]
        var qohString = ""
        product.quantityOnHand() > 0 ? (qohString = NSLocalizedString("(\(product.quantityOnHand()) in stock)", comment: "QoH String")) : (qohString = NSLocalizedString("(out of stock)", comment: "Out of Stock String"))
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "productCell", for: indexPath as IndexPath)

        cell.textLabel?.text = product.productName
        cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        cell.detailTextLabel?.numberOfLines = 3
        cell.detailTextLabel?.text = "\(product.productDescription) \(qohString)"
        if let productImage = product.image { // we have an image in the data
            cell.imageView?.image = UIImage(data:productImage)?.resizeImage(targetSize: CGSize(width:110, height:110))
        } else { // use the placeholder image
            cell.imageView?.image = UIImage(named: "Package")?.resizeImage(targetSize: CGSize(width:110, height:110))
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: kInventoryToProductDetail, sender: self)
    }
    
    // MARK: - Navigation
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kInventoryToProductDetail {
            let indexPath = tableView.indexPathForSelectedRow
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            
            let vc = segue.destination as? ProductDetailViewController
            vc!.productId = products![indexPath!.row].id
            vc!.hidesBottomBarWhenPushed = true
        }
        
        if segue.identifier == kInventoryToNewProduct {
            self.navigationController?.setNavigationBarHidden(false, animated: false)

            let vc = segue.destination as? ProductDetailViewController
            vc?.navigationItem.title = NSLocalizedString("New Task", comment: "New Task")
            vc?.newProductMode = true
            if newProductID != nil {
                vc?.productId = newProductID!
            }
            vc?.navigationItem.title = NSLocalizedString("New Product", comment: "New Product")
            vc?.hidesBottomBarWhenPushed = true
        }
        
        if segue.identifier == kSortingPopoverSegue {
            let sortSelectorController = segue.destination as! SortOptionsTableViewController
            sortSelectorController.preferredContentSize = CGSize(width:250, height:150)
            sortSelectorController.delegate = self // needed so we get the didChangeSortOptions delegate call
            sortSelectorController.currentlySelectedSortOption = self.sortProperty
            
            let popoverController = sortSelectorController.popoverPresentationController
            if popoverController != nil {
                popoverController!.delegate = self
                popoverController!.backgroundColor = UIColor.black
            }
        }
        
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    // this enables the swipe gestures to/from the task detail via the tasks storyboard
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    //MARK: UISearchBar delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange textSearched: String) {
        print("typing in search bar: term = \(textSearched)")
        if textSearched != "" {
            let predicate = NSPredicate(format:"productName CONTAINS[c] %@ OR productDescription CONTAINS[c] %@ OR id CONTAINS[c] %@", textSearched, textSearched, textSearched)

            products = realm.objects(Product.self).filter(predicate)
        } else {
            products = realm.objects(Product.self).sorted(byKeyPath: sortProperty, ascending: sortAscending ? true : false)
        }
        tableView.reloadData()
    }
    
    // MARK: SortOptionsSelectionProtocol delegate method(s)
    
    func didChangeSortOptions(sortTitle: String, sortProperty: String) {
        self.sortProperty = sortProperty
        self.navigationItem.leftBarButtonItem?.title = NSLocalizedString("by \(sortTitle)", comment: "'Sorted by' interpolation with user selection of sorting Title")
    }
    
    @IBAction  func toggleSortDirection() {
        sortAscending = !self.sortAscending
        self.restortEntries()
    }
    
    func restortEntries() {
        sortDirectionButtonItem.title = self.sortAscending ? "↑" : "↓"
        self.navigationItem.leftBarButtonItem?.title = NSLocalizedString("by \(self.sortProperty)", comment: "'Sorted by' interpolation with user selection of sorting Title")
        products = self.products?.sorted(byKeyPath: self.sortProperty, ascending: self.sortAscending ? true : false)
        tableView.reloadData()
    }
    
    // MARK: Actions
    @IBAction func scanBarcodeTapped(_ sender: Any) {
        if UIDevice.isSimulator == false {
            let controller = BarcodeScannerController()
            controller.codeDelegate = self
            controller.errorDelegate = self
            controller.dismissalDelegate = self
            present(controller, animated: true, completion: nil)
        } else {
            inSimulatorAlert(message: NSLocalizedString("Barcode scanner unavailable in the iOS Simulator", comment: "No scanner in the simulator"))
        }
    }
    
    
    @IBAction func addButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: kInventoryToNewProduct, sender: self)
    }
    
    func jumpToProduct(productId: String) {
        // scroll the products list to the indicated productId
    }
    
    func findByProductID(productId: String) -> Bool{
        if let result = products?.filter("id = %@", productId).first {
            return true
        } else {
            return false
        }
    }

    // MARK: Utilities
    func inSimulatorAlert(message: String) {
        let alert = UIAlertController(title: NSLocalizedString("iOS Simulator", comment: "alert title"), message: message, preferredStyle: .alert)
        
        // Cancel button
        let cancelAction = UIAlertAction(title: "OK", style: .cancel) { (action:UIAlertAction!) in
        }
        alert.addAction(cancelAction)
        
        // Present Dialog message
        present(alert, animated: true, completion:nil)
    }
    
    func proposeNewProduct(productId: String) {
        let message = NSLocalizedString("Create a new product for id \(productId)?", comment: "Create new product?")
        let alert = UIAlertController(title: NSLocalizedString("Unknown Product ID", comment: "alert title"), message: message, preferredStyle: .alert)
        
        let createAction = UIAlertAction(title: NSLocalizedString("Create", comment: "Create"), style: .default) { (action:UIAlertAction!) in
            self.newProductID = productId
            self.performSegue(withIdentifier: kInventoryToNewProduct, sender: self)
        }
        alert.addAction(createAction)

        // Cancel button
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction!) in
            print("Cancel button tapped");
        }
        alert.addAction(cancelAction)
        
        // Present Dialog message
        present(alert, animated: true, completion:nil)
    }
} // of ProductsTableViewController


extension ProductsTableViewController: BarcodeScannerCodeDelegate {
    
    func barcodeScanner(_ controller: BarcodeScannerController, didCaptureCode code: String, type: String) {
        print(code)
        controller.reset()
        controller.dismiss(animated: true, completion: nil)
        if findByProductID(productId: code) {
            jumpToProduct(productId: code)
        } else {
            proposeNewProduct(productId: code);
        }
    }
}

extension ProductsTableViewController: BarcodeScannerErrorDelegate {
    
    func barcodeScanner(_ controller: BarcodeScannerController, didReceiveError error: Error) {
        print(error)
    }
}


extension ProductsTableViewController: BarcodeScannerDismissalDelegate {
    
    func barcodeScannerDidDismiss(_ controller: BarcodeScannerController) {
        controller.dismiss(animated: true, completion: nil)
    }
}


