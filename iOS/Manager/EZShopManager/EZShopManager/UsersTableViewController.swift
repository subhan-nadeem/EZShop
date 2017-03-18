//
//  UsersTableViewController.swift
//  EZShopManager
//
//  Created by Jung Geon Choi on 2017-03-18.
//  Copyright © 2017 Jung Geon Choi. All rights reserved.
//

import UIKit
import SwiftyJSON
import FirebaseDatabase
import Kingfisher

protocol UserTableDelgate {
	func didSelectUser(user: User)
}

class UsersTableViewController: UITableViewController {
	var delegate: UserTableDelgate?
	var ref: FIRDatabaseReference!
	var showInStore = true
	@IBAction func segView(_ sender: UISegmentedControl) {
		showInStore = sender.selectedSegmentIndex == 0
		tableView.reloadData()
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		tableView.tableFooterView = UIView()

		ref = FIRDatabase.database().reference()
		let refHandle = ref.observe(FIRDataEventType.value, with: { (snapshot) in
			let db = JSON(snapshot.value)
			//print(db["users"])

			if let _users = db["users"].dictionary {
				self.users.removeAll()
				_users.forEach({ (_, _userJSON) in
					let new = User()
					print(_userJSON["user_id"].stringValue)
					new.name = _userJSON["name"].stringValue
					new.photo = _userJSON["photo"].stringValue
					new.user_id = _userJSON["user_id"].stringValue
					new.isInStore = _userJSON["is_in_store"].boolValue

					if let store = db["store"].dictionary {
						if let _items = store[new.user_id]?["cart"].arrayObject as? [Int] {
							_items.forEach({ (_item_id) in
								let newItem = Item()
								newItem.item_id = _item_id

								let _itemDetails = db["inventories"][_item_id].dictionaryValue
								newItem.item_name = _itemDetails["item_name"]!.stringValue
								newItem.item_price = _itemDetails["item_price"]!.doubleValue
								new.items.append(newItem)
							})
						}
					}
					print(new.items)
					self.users.append(new)
				})

				self.tableView.reloadData()

					if self.selecteedIndex != nil {
						if (self.selecteedIndex?.row)! < self.dataSource().count {
							self.delegate?.didSelectUser(user: self.dataSource()[(self.selecteedIndex?.row)!])
						}
				}


			}
		})
	}



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	var selecteedIndex:IndexPath?
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		delegate?.didSelectUser(user: dataSource()[indexPath.row])

		if selecteedIndex != nil {
			tableView.cellForRow(at: selecteedIndex!)?.accessoryType = .none
		}
		selecteedIndex = indexPath
		tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark

		tableView.deselectRow(at: indexPath, animated: true)
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource().count
    }

	var users: [User] = []

	func dataSource() -> [User] {
		return users.filter({ (user) -> Bool in
			if showInStore {
				return user.isInStore
			}
			return true
		})
	}


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath)
		let user = dataSource()[indexPath.row]
		if let imageView = cell.viewWithTag(100) as? UIImageView {
			imageView.layer.cornerRadius = imageView.frame.width/2
			imageView.clipsToBounds = true
			imageView.kf.setImage(with: URL(string: user.photo))
		}

		if let nameLabel = cell.viewWithTag(101) as? UILabel {
			nameLabel.text = user.name
		}
		cell.accessoryType = .none
        return cell
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
