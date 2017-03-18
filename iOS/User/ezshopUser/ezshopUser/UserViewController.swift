//
//  UserViewController.swift
//  ezshopUser
//
//  Created by Jung Geon Choi on 2017-03-18.
//  Copyright © 2017 Jung Geon Choi. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Kingfisher
import FirebaseMessaging
import SwiftyJSON

import Firebase
//import FirebaseMessaging
import UserNotifications

class UserViewController: UIViewController {
var ref: FIRDatabaseReference!
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var totalLabel: UILabel!
	@IBAction func logout(_ sender: Any) {
		User.instance = User()
		User.setUserName(name: "")
		performSegue(withIdentifier: "ShowLogin", sender: nil)
	}
	@IBOutlet weak var statusLabel: UILabel!

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var circleView: UIView!
	@IBOutlet weak var nameLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

		


		updateView()
		imageView.layer.cornerRadius = imageView.frame.width/2

		self.ref = FIRDatabase.database().reference()

		ref.child("users").child(User.instance.user_id).updateChildValues(["fcm_token":FIRInstanceID.instanceID().token()])

		let refHandle = self.ref.observe(FIRDataEventType.value, with: { (snapshot) in
			let db = JSON(snapshot.value)
			//print(db["users"])

			if let _users = db["users"].dictionary {
				_users.forEach({ (_, _userJSON) in
					if User.instance.user_id == _userJSON["user_id"].stringValue {
						let new = User()
						print(_userJSON["user_id"].stringValue)
						new.name = _userJSON["name"].stringValue
						new.photo = _userJSON["photo"].stringValue
						new.user_id = _userJSON["user_id"].stringValue
						new.isInStore = _userJSON["is_in_store"].boolValue

						if let store = db["store"].dictionary {
							if let _items = store[new.user_id]?["cart"].arrayObject as? [Int] {
								print(store[new.user_id])
								print(_items)
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

						User.instance = new
						self.updateView()
					}
				})
			}
		})
	}

	func updateView() {
		tableView.reloadData()
		totalLabel.text = ""
		if User.instance.isInStore {
			var total = 0.00
			User.instance.items.forEach({ (item) in
				total += item.item_price
			})
			totalLabel.text = String(format: "$ %.2f", total)
		}
		nameLabel.text = User.instance.name
		statusLabel.text = User.instance.isInStore ? "Currently you are in store" : "Currently you are not in store"
		circleView.layer.cornerRadius = circleView.frame.width/2
		circleView.clipsToBounds = true
		circleView.backgroundColor = User.instance.isInStore ? UIColor.green : UIColor.red
		tableView.tableFooterView = UIView()
		cartCover.removeFromSuperview()
		imageView.kf.setImage(with: URL(string: User.instance.photo))
		if User.instance.items.count == 0 || !User.instance.isInStore {
			cartCover = UIView(frame: tableView.frame)
			cartCover.backgroundColor = UIColor.white
			let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 50)))
			label.text = "Cart is Empty"
			label.textAlignment = .center
			label.font = UIFont.boldSystemFont(ofSize: 50)
			//			label.center = cartCover.center
			cartCover.addSubview(label)
			view.addSubview(cartCover)
		}
	}
	var cartCover = UIView()

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension UserViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return User.instance.items.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
		let item = User.instance.items[indexPath.row]
		cell.textLabel?.text = item.item_name
		cell.detailTextLabel?.text = "$ \(item.item_price)"


		return cell
	}

	
}
