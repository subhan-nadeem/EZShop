//
//  ViewController.swift
//  ezshopUser
//
//  Created by Jung Geon Choi on 2017-03-18.
//  Copyright © 2017 Jung Geon Choi. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SwiftyJSON

struct KairosConfig {
	static let app_id = "4724eb0e"
	static let app_key = "f5795e224117ac3393343c6bc14c841b"
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
	var ref: FIRDatabaseReference!

	@IBAction func login() {
		let imagePicker = UIImagePickerController()
		imagePicker.view.tintColor = view.tintColor
		imagePicker.sourceType = .camera
		imagePicker.delegate = self
		imagePicker.cameraDevice = .front

		imagePicker.allowsEditing = true

		present(imagePicker, animated: true)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}



	func clFaceDetectionImagePickerDidDismiss(_ data: Data!, blnSuccess: Bool) {
		if data != nil {
			if let image = UIImage(data: data) {
				let Kairos = KairosAPI(app_id: KairosConfig.app_id, app_key: KairosConfig.app_key)
				let imageData = UIImageJPEGRepresentation(image, 1)
				let base64ImageData = imageData?.base64EncodedString(options:[])
				// setup json request params, with base64 data
				let jsonBody = [
					"image": base64ImageData,
					"gallery_name": "ezshop"
				]


				Kairos.request(method: "recognize", data: jsonBody) { data in

					let json = JSON(data)
					print(json)
				}
			}
		}
	}

	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: nil)
	}

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

		dismiss(animated: true, completion: nil)
		ActivityIndicator.shared.show(self.view)

		if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
			let Kairos = KairosAPI(app_id: KairosConfig.app_id, app_key: KairosConfig.app_key)
			let imageData = UIImageJPEGRepresentation(image, 1)
			let base64ImageData = imageData?.base64EncodedString(options:[])
			// setup json request params, with base64 data
			let jsonBody = [
				"image": base64ImageData,
				"gallery_name": "ezshop"
			]


			Kairos.request(method: "recognize", data: jsonBody) { data in

				let json = JSON(data)
//				print(json)
				let images = json["images"].arrayValue
				let image = images.first?.dictionaryValue
				let candidates = image?["candidates"]?.arrayValue
				let candidate = candidates?.first
				print(candidate?["subject_id"])
				print(candidate?["confidence"])
				if let candidate = candidate {
					let subject_id = candidate["subject_id"].stringValue
					let confidence = Int(candidate["confidence"].doubleValue * 100.0)
					if confidence < 60 {
						ActivityIndicator.shared.hide()
						JGUtils.alert(title: "Error", message: "Too low confidence")
					} else {
						self.ref = FIRDatabase.database().reference()
						let refHandle = self.ref.observe(FIRDataEventType.value, with: { (snapshot) in
							let db = JSON(snapshot.value)
							self.ref.removeAllObservers()
							//print(db["users"])

							if let _users = db["users"].dictionary {
								_users.forEach({ (_, _userJSON) in
									if subject_id == _userJSON["user_id"].stringValue {
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
									}
								})
							}

							if User.instance.name == "" {
								ActivityIndicator.shared.hide()
								JGUtils.alert(title: "ERROR", message: "This user is not registered")
							} else {
								//							User.setUserName(name: self.userNameLabel.text!)
								JGUtils.alert(title: "WELCOME", message: "Hello \(User.instance.name)\n\n\(confidence)% confidence", closure: {
									ActivityIndicator.shared.hide()
									self.performSegue(withIdentifier: "ShowUser", sender: nil)
								})
								User.setUserName(name: User.instance.user_id)
								//							self.userNameLabel.text = ""
							}
						})
					}

				} else {
					DispatchQueue.main.sync {
						JGUtils.alert(title: "ERROR", message: "Could not find the match")
						ActivityIndicator.shared.hide()
					}

				}





			}
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		self.ref = FIRDatabase.database().reference()
		let refHandle = self.ref.observe(FIRDataEventType.value, with: { (snapshot) in
			let db = JSON(snapshot.value)
			//print(db["users"])

			if let _users = db["users"].dictionary {
				_users.forEach({ (_, _userJSON) in
					if User.getUserName() == _userJSON["user_id"].stringValue {
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
					}
				})
			}

			if User.instance.name == "" {
//				JGUtils.alert(title: "ERROR", message: "This user is not registered")
			} else {
				//							User.setUserName(name: self.userNameLabel.text!)
//				JGUtils.alert(title: "WELCOME", message: "Hello \(User.instance.name)\n\n\(confidence)% confidence", closure: {
					ActivityIndicator.shared.hide()
					self.performSegue(withIdentifier: "ShowUser", sender: nil)
//				})
//				User.setUserName(name: User.instance.user_id)
				//							self.userNameLabel.text = ""
			}
		})
	}


	}
//		userNameLabel.text = User.getUserName()
//		ref = FIRDatabase.database().reference()
//		let refHandle = ref.observe(FIRDataEventType.value, with: { (snapshot) in
//			let db = JSON(snapshot.value)
//			//print(db["users"])
//
//			if let _users = db["users"].dictionary {
//				_users.forEach({ (_, _userJSON) in
//					if self.userNameLabel.text?.lowercased() == _userJSON["name"].stringValue.lowercased() {
//						let new = User()
//						print(_userJSON["user_id"].stringValue)
//						new.name = _userJSON["name"].stringValue
//						new.photo = _userJSON["photo"].stringValue
//						new.user_id = _userJSON["user_id"].stringValue
//						new.isInStore = _userJSON["is_in_store"].boolValue
//
//						if let store = db["store"].dictionary {
//							if let _items = store[new.user_id]?["cart"].arrayObject as? [Int] {
//								print(store[new.user_id])
//								print(_items)
//								_items.forEach({ (_item_id) in
//									let newItem = Item()
//									newItem.item_id = _item_id
//
//									let _itemDetails = db["inventories"][_item_id].dictionaryValue
//									newItem.item_name = _itemDetails["item_name"]!.stringValue
//									newItem.item_price = _itemDetails["item_price"]!.doubleValue
//									new.items.append(newItem)
//								})
//							}
//						}
//
//						User.instance = new
//					}
//				})
//			}
//			if User.instance.name == "" {
//				//				JGUtils.alert(title: "ERROR", message: "This user is not registered")
//			} else {
//				self.performSegue(withIdentifier: "ShowUser", sender: nil)
//				self.userNameLabel.text = ""
//			}
//		})
//	}

	
	


