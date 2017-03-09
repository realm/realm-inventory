# Inventory
## A Realm Mobile Platform Example Application


## Intro

This app is a simple implementation of an idealized inventory tracking system designed to show how transaction safe counters can be implemented in a mobile application.

# Installation

## Prerequisites

This app uses [Cocoapods](https://www.cocoapods.org) to set up the project's 3rd party dependencies. Installation can be directly (from instructions at the Cocapods site) or alternatively through a package management system like [Homebrew](brew.sh/).

### Realm Mobile Platform

This application demonstrates features of the [Realm Mobile Platform](http://lrealm.io) and needs to have a working instance of the Realm Object Server available to make tasks, and other data available between instances of the Fieldwork app. The Realm Mobile Platform can be downloaded from [Realm Mobile Platform](http://realm.io) and exists in two forms, a ready-to-run macOS version of the server, and a Linux version that runs on RHEL/CentOS versions 6/7 and Ubuntu as well as several Amazon AMIs and Digital Ocean Droplets. The macOS version can be run with the Fieldwork right out of the box; the Linux version will require access to a Linux server.


### 3rd Party Modules

The following modules will be installed as part of the Cocoapods setup:

- [RealmSwift](https://realm.io)  The Realm bindings for Cocoa/Swift

- [Realm LoginKit](https://github.com/realm-demos/realm-loginkit) A Realm control for logging in to Realm servers

- [BarcodeScanner](https://github.com/hyperoslo/BarcodeScanner) an elegant barcode scanner module for iOS

- [Eureka](https://github.com/xmartlabs/Eureka) a formbuilder for iOS in Swift by xmartlabs

- [ImagePicker](https://github.com/hyperoslo/ImagePicker.git) for selection of photo library images by Hyper.no

- [PermissionScope](https://github.com/nickoneill/PermissionScope.git) permission management dialog by Nick O'Neill

## Preparing the Realm Object Server

The Inventory application can be used with any version of the Realm Object Server (Developer, Professional or Enterprise).  The Inventory app needs to be able to set permissions on the Realm used by the app - this must be done by a Realm user that has permission/rights to administer the server.  This could be the first account you set up as part of the Realm Object Server installation, or any account that has the admin bit set.

You can determine which accounts have admin rights by logging in to the Realm Object Server Dashboard:
![ROS Dashboard User Listing](/Graphics/ROS-Users-List.png)

You create new users (and give them admin rights) on this screen.

You can set the admin rights for existing users by clicking-through to the user's profile page and checking the "can administer this server" checkbox:
![ROS Dashboard User Listing](/Graphics/ROS-User-Detail.png)


Once you have created or selected an admin user to use, you can proceed with compiling and running Fieldwork.



## Compiling & Running the Application

Before attempting to compile the project, install all of its dependencies using Cocoapods by invoking ``pod install``. This is done by opening a Terminal window and changing to the directory where you downloaded the Fieldwork repository. In this main directory is a Folder called `IventoryApp` that contains `Podfile` needed by `CocoaPods` as well as the application sources.


This process will create a ``Pods`` directory which contains all of the compiled resources needed by the app, along with an Xcode xcworkspace file which you will open and work with instead
of the `Inventory.xcproject` file when building/running this application.

Once the cocoapods have been retrieved, open the ``Inventory.xcworkspace`` file and press build.  The app should compile cleanly.

### First Login

As mentioned above, the first login to the Inventory app needs to be by a user enabled with administrative privileges on the Realm Object Server.  This is to enable a global Read/Write permission on the shared Realm that is created by the application.

### Adding Users

Adding users can be done either via the Realm Dashboard, or by adding users using the Inventory the app itself from the login screen.
<center> <img src="/Graphics/Inventory-Signup.png" width="310" height="552" /></center><br>



## Navigating Inventory
The Inventory app is a simple "tab bar" application - that is to say it supports a number of main views that are accessible at all times:

<center> <img src="/Graphics/Inventory-TabBar.png" width="621" height="71.5"/><br/>Tab Bar</center> <br/>
In this case, Inventory is very simple and supports just the main products list (in essence the "inventory" managed by the app) and a settings screen on which you can manage your profile or log out of the app.

The app does support several other detail screens that are explained along with the main applications screens these are:
 * Product view
 * Settings view
 * Barcode scanning view for finding existing or creating new products)
 * Product Detail view for seeing the details of existing products
 * Product entry view for entering the details of a newly created product

### App Permissions
_Inventory_ shows how do use some specialized features of Realm and is not meant to be a full-blown inventory system; never the less is can be used my multiple users as a way to try out the safe counters and sync'd transactions demonstrated here. In order to enable multiple users Inventory implements a top-level Realm named "Inventory" that has its permissions set to "* RW" which in [Realm's permission structure](https://realm.io/docs/swift/latest/#modifying-permissions) is a wildcard read/write permission.

In order to set up the app fo multi-user access, the first user to log in using this app needs to be a Realm admin user -- that is usually the user ID of the person who set up the Realm object server; it can also be any other user who has been granted admin permissions via the Realm dashboard. See [Preparing the Realm Object Server](#Preparing-the-Realm-Object-Server), above.

### The Products View
<center> <img src="/Graphics/Inventory-Product-Listing.png" width="310" height="552" /><br/>Product Listing</center><br>

Products can be viewed across a number of dimensions - tapping the sort menu in the upper-left corner of the products view will bring up the sort options menu, and tapping the arrow immediately to the right will change the sorting direction

<center> <img src="/Graphics/Inventory-Products-SortMenu.png" width="310" height="552" /></center><br>

### The Barcode Scanner & Product Detail Entry

In order to use the barcode scanner built in to Inventory, you must give permission for the Inventory app to access the iOS device's camera:

<center> <img src="/Graphics/Inventory-Camera-Permissions.png" width="310" height="552" /></center>Camera Permission Request<br>

However, if you are running this application in the OS simulator under Xcode, there is no camera to access.  You will need to enter product UPC codes by hand when using the simulator:

<center> <img src="/Graphics/Inventory-Barcode-Simulator-Warning.png" width="310" height="552" /></center>Simulator Warning<br>

# New Product Creation
A new product can be entered into Inventory in 2 ways:

  - tapping the "+" button on the product listing screen. This will bring up an empty form that can be filled in
  <center> <img src="/Graphics/Inventory-New-Product.png" width="310" height="552" /></center><br>

  - Scanning a barcode - if the (UPC) scan code is not currently represented in the products:
  <center> <img src="/Graphics/Inventory-Barcode-Scanning.png" width="310" height="552" /></center>Barcode Scanning<br>


If the product is not yet in the system you are given the option to add it:
  <center> <img src="/Graphics/Inventory-Scancode-Not-Found.png" width="310" height="552" /></center>Scancode Not Found<br>


Adding a product image to your inventory record:
<center> <img src="/Graphics/Inventory-TakePhoto.png" width="310" height="552" /></center><br>


If a product you scanned is _already_ in the inventory system, it will be displayed:
<center> <img src="/Graphics/Inventory-NewProduct-Scanned.png" width="310" height="552" /></center>Successful Scan<br>

## Other Ways to Search

The main products view also supports a search bar that will allow search to be done for any of the product item fields.


# Adding/Removing Inventory
You can add to or remove items from inventory for  given product on it's detail screen:
<center> <img src="/Graphics/relm-inventory-product-detail-add.png" width="310" height="552" /></center><br>

The counter and button will indicate the number to be added or subtracted, pressing the button will write the transaction to the Realm and update all the counters visible in the app live and in real-time (and if your app is online in the views other other users as well).
<center> <img src="/Graphics/relm-inventory-product-detail-add-success.png" width="310" height="552" /></center><br>




# Settings / Profile

<center> <img src="/Graphics/Inventory-Settings.png" width="310" height="552" /></center><br>


# Application Architecture


### Tracking Additions and Subtractions From Inventory

One of the interesting aspects of a mobile application is the fact it -- to be truly useful -- needs to work both online _and_ offline.  Our inventory application as an additional constraint: it needs to support changing quantities inside the application in a consistent and mathematically correct way regardless of how many users are accessing or updating the items.

While this may seem self-evident, supporting arithmetical atomicity is tricky.  Realm supports 2 different ways of ensuring that transactions (additions or subtractions) from inventories: Lists and Counters.

#### Method 1: Lists

TBD: show how adding up the transactions in a list will yield a consistent result w/out the use of atomic counters.

Let's look at a transaction log for a few hypothetical products:
<center> <img src="/Graphics/Inventory-Transaction-log-plain.png" /></center><br>

Here we see there several products - (product ID's 1,2 3 and 5) each with several additions or removals (sales) from the inventory.

If we highlight just the activity for product 1, we can see quickly where this goes - adding up the amounts of all the transactions tells use the current quantity on-hand of product #1.  This is a very safe way to implement a transaction safe counting system.  It also has the ability to allow us to create a rich system where we can add more color (metadata) to our inventory system (like the ID of who sold what, what store or region did gets credit for a sale, etc).
<center> <img src="/Graphics/Inventory-Transaction-log-highlighted.png"/></center><br>

#### Method 2: Counters

This method will be described in the next update to this demo.

# Models
The Inventory app consists of two basic models - a *Product*:
``` swift
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
    let transactions = List<Transaction>()
}
```

...and a *Transaction*:

```swift
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
// :
// more class methods
// :
} // of the Product class
```

The Product class is a minimalistic, idealized implementation of what a product in an inventory system might look like.  The transaction class tracks all the required info about an addition to or sale from the inventory for any product.  The key things to note in the Product class are:

1. We use a Realm list property to be able to find all of the transactions (sales, and inventory replenishments) that are booked against this product, and

2.  The "amount" property is not actually stored in the Realm itself but is a synthesized property whose getter uses a class method that uses [Realm's aggregation functions](https://realm.io/docs/swift/latest/api/Classes/AnyRealmCollection.html#/s:FC10RealmSwift18AnyRealmCollection3sumuRd__S_11AddableTyperFT10ofPropertySS_qd__) to do math for us:

```swift
func quantityOnHand() -> Int {
    let realm = try! Realm()
    let transactions = realm.objects(Transaction.self).filter("productId = %@", self.id)
    return transactions.sum(ofProperty: "amount")
}
```

The result of the use of the transaction list and the synthesis of the amount on hand using [Realm's aggregation functions](https://realm.io/docs/swift/latest/api/Classes/AnyRealmCollection.html#/s:FC10RealmSwift18AnyRealmCollection3sumuRd__S_11AddableTyperFT10ofPropertySS_qd__) enables multiple users to use an app like _Inventory_ and not worry about collisions or math errors.
Of course one can add any number of multi-user safe such operations. The implementation file here includes a `quantitySold()` function and the prototypes for functions to determine quantities sold across date ranges as well.



# License

 The Realm Inventory is distributed under the terms of the  [MIT License](https://en.wikipedia.org/wiki/MIT_License)
