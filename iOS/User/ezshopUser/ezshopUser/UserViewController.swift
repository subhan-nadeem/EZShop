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
		ref.child("users").child(User.instance.user_id).updateChildValues(["fcm_token":"invalid"])
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

		imageView.layer.cornerRadius = imageView.frame.width/2
		imageView.clipsToBounds = true

		circleView.layer.cornerRadius = circleView.frame.width/2
		updateView()


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
									if _item_id > 0 {
										let newItem = Item()
										newItem.item_id = _item_id

										let _itemDetails = db["inventories"][_item_id].dictionaryValue
										newItem.item_name = _itemDetails["item_name"]!.stringValue
										newItem.item_price = _itemDetails["item_price"]!.doubleValue
										new.items.append(newItem)
									}

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

		circleView.clipsToBounds = true

var transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
//		circleView.transform = CGAffineTransform.identity
//		imageView.transform = CGAffineTransform.identity

		UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, options: [], animations: { 
			var transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
			self.circleView.transform = transform
			self.imageView.transform = transform

		}) { (_) in
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, options: [], animations: { 
				self.circleView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
				self.imageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)


				self.circleView.backgroundColor = User.instance.isInStore ? UIColor.green : UIColor.red
			}, completion: nil)

		}





		tableView.tableFooterView = UIView()
		cartCover.removeFromSuperview()
		imageView.kf.setImage(with: URL(string: User.instance.photo))
		if User.instance.items.count == 0 {
			cartCover = UIView(frame: tableView.frame)
			cartCover.backgroundColor = UIColor.white
			let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 20)))
			label.text = "Cart is Empty"
			label.textColor = UIColor.black.withAlphaComponent(0.5)
			label.textAlignment = .center
			label.frame = CGRect(x: 0, y: tableView.frame.height/2, width: tableView.frame.width, height: 30)
			label.font = UIFont.italicSystemFont(ofSize: 15)
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
