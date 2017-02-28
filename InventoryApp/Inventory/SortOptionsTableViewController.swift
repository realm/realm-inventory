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

protocol SortOptionsSelectionProtocol {
    func didChangeSortOptions(sortTitle: String, sortProperty: String)
}

class SortOptionsTableViewController: UITableViewController {

    let sortOptions: Array<Dictionary<String, String>> = [
        ["productName": NSLocalizedString("Name", comment: "Name")],
        ["lastUpdated": NSLocalizedString("Updated", comment: "Updated")],
        ["amount": NSLocalizedString("Quantity", comment: "Quantity")]
    ]

    var delegate: SortOptionsSelectionProtocol?
    let cellIdentifier = "SortOptionsCell"
    var currentlySelectedSortOption = "productName" // start out with name
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // the sort option may have chanvges since last we were here... so check to see of the caller has set is
        if currentlySelectedSortOption.isEmpty {
            currentlySelectedSortOption = "productName"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortOptions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)

        let theOption: Dictionary<String,String> = sortOptions[indexPath.row]
        cell.textLabel?.text = theOption.values.first
        if self.currentlySelectedSortOption == theOption.keys.first! {
            cell.accessoryType = .checkmark
        } else{
            cell.accessoryType = .none
        }
        return cell
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let theOption: Dictionary<String,String> = sortOptions[indexPath.row]
        delegate?.didChangeSortOptions(sortTitle: theOption.values.first!, sortProperty: theOption.keys.first!)
        self.dismiss(animated: true, completion: nil)
    }
    
}
