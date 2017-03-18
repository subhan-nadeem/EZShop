//
//  EnrollViewController.swift
//  EZShopManager
//
//  Created by Jung Geon Choi on 2017-03-17.
//  Copyright © 2017 Jung Geon Choi. All rights reserved.
//

import UIKit
import SwiftyJSON
import FirebaseDatabase
import FirebaseStorage


struct KairosConfig {
	static let app_id = "4724eb0e"
	static let app_key = "f5795e224117ac3393343c6bc14c841b"
}

class EnrollViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLFaceDetectionImagePickerDelegate {
	@IBOutlet weak var userNameLabel: UITextField!
	var uuid = ""
	var images: [UIImage] = []
	@IBAction func takePhoto() {
		if userNameLabel.text == "" {
			JGUtils.alert(title: "ERROR", message: "Enter user name")
		}
		uuid = UUID().uuidString
		userNameLabel.resignFirstResponder()
		JGUtils.alert(title: "Instruction", message: "Hold ipad on your eye level. It will take 3 photos. Press OK to start") { 
			let imagePicker = CLFaceDetectionImagePickerViewController()
			imagePicker.delegate = self

			self.present(imagePicker, animated: true)
			let view = UIView(frame: self.view.frame)
			view.backgroundColor = UIColor.white

			let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: 100)))
			label.text = self.messages[self.images.count]
			label.font = UIFont.systemFont(ofSize: 50)
			label.sizeToFit()

			view.addSubview(label)
			label.center = view.center
			self.view.addSubview(view)
			self.tempMessageContainer = view
		}


//		imagePicker.view.tintColor = view.tintColor
//		imagePicker.sourceType = .camera
//		imagePicker.delegate = self
//		imagePicker.cameraDevice = .front
//
//		imagePicker.allowsEditing = true
//		present(imagePicker, animated: true, completion: nil)
	}

	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: nil)
	}

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
			uuid = UUID().uuidString
			// Instantiate KairosAPI class
			let Kairos = KairosAPI(app_id: KairosConfig.app_id, app_key: KairosConfig.app_key)


			let imageData = UIImageJPEGRepresentation(image, 0)
			let base64ImageData = imageData?.base64EncodedString(options:[])

			// setup json request params, with base64 data
			let jsonBody = [
				"image": base64ImageData,
				"gallery_name": "ezshop",
				"subject_id": uuid
			]

			// Example - Enroll
			ActivityIndicator.shared.show(self.view)
			Kairos.request(method: "enroll", data: jsonBody) { data in
				let json = JSON(data)
//				print(json)
				DispatchQueue.main.sync {
					JGUtils.alert(title: "SUCCESS", message: "User is enrolled")
					self.enrollUser(image: image)
					ActivityIndicator.shared.hide()
				}
			}
			self.dismiss(animated: true, completion: nil)
		}

	}

	func enrollUser(image: UIImage) {
		uploadImage(image: image)

	}
var photoURL = ""
	func uploadImage(image: UIImage) {
		let storage = FIRStorage.storage()
		// Create a root reference
		let storageRef = storage.reference()

		// Data in memory
		let data = UIImageJPEGRepresentation(image, 0.5)

		// Create a reference to the file you want to upload
		let riversRef = storageRef.child("images/" + uuid + ".jpg")

		// Upload the file to the path "images/rivers.jpg"
		let uploadTask = riversRef.put(data!, metadata: nil) { (metadata, error) in
			guard let metadata = metadata else {
    // Uh-oh, an error occurred!
    return
			}
			// Metadata contains file metadata such as size, content-type, and download URL.
			self.photoURL = metadata.downloadURLs!.first!.absoluteString
			let ref = FIRDatabase.database().reference()
			ref.child("users").child(self.uuid).setValue(
				["name": self.userNameLabel.text!,
				 "user_id": self.uuid,
				 "is_in_store": false,
				 "photo": self.photoURL])
			self.userNameLabel.text = ""

		}
	}
	var tempMessageContainer:UIView = UIView()
	let messages = ["Taking photo 1/3","☺️Smile :D", "Last one!"]
	func clFaceDetectionImagePickerDidDismiss(_ data: Data!, blnSuccess: Bool) {
		tempMessageContainer.removeFromSuperview()
		if data != nil {
			if let image = UIImage(data: data) {
				if images.count < 2 {
					images.append(image)
					let view = UIView(frame: self.view.frame)
					view.backgroundColor = UIColor.white

					let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: 100)))
					label.text = messages[images.count]
					label.font = UIFont.systemFont(ofSize: 50)
					label.sizeToFit()
					label.textAlignment = .left

					view.addSubview(label)
					label.center = view.center
					self.view.addSubview(view)
					tempMessageContainer = view


					let imagePicker = CLFaceDetectionImagePickerViewController()
					imagePicker.delegate = self
					present(imagePicker, animated: true, completion: nil)
				} else {
					images.append(image)
					// Instantiate KairosAPI class
					let Kairos = KairosAPI(app_id: KairosConfig.app_id, app_key: KairosConfig.app_key)




										// Example - Enroll
					ActivityIndicator.shared.show(self.view)

					let imageData = UIImageJPEGRepresentation(self.images[0], 1)
					let base64ImageData = imageData?.base64EncodedString(options:[])
					// setup json request params, with base64 data
					let jsonBody = [
						"image": base64ImageData,
						"gallery_name": "ezshop",
						"subject_id": self.uuid
					]


					Kairos.request(method: "enroll", data: jsonBody) { data in
						print("Photo 1")
						let json = JSON(data)
						print(json)
						let imageData = UIImageJPEGRepresentation(self.images[1], 1)
						let base64ImageData = imageData?.base64EncodedString(options:[])
						// setup json request params, with base64 data
						let jsonBody = [
							"image": base64ImageData,
							"gallery_name": "ezshop",
							"subject_id": self.uuid
						]


						Kairos.request(method: "enroll", data: jsonBody) { data in
							let json = JSON(data)
							print("Photo 2")
							print(json)
							let imageData = UIImageJPEGRepresentation(self.images[2], 1)
							let base64ImageData = imageData?.base64EncodedString(options:[])
							// setup json request params, with base64 data
							let jsonBody = [
								"image": base64ImageData,
								"gallery_name": "ezshop",
								"subject_id": self.uuid
							]


							Kairos.request(method: "enroll", data: jsonBody) { data in
								let json = JSON(data)
								print("Photo 3")
								print(json)

								DispatchQueue.main.sync {
									JGUtils.alert(title: "SUCCESS", message: "User is enrolled")
									self.enrollUser(image: self.images[2])
									self.images.removeAll()
									ActivityIndicator.shared.hide()

									self.tabBarController?.selectedIndex = 1
								}
							}
						}
					}

				}
			}
		}


	}

	@IBAction func gotostore() {
		self.tabBarController?.selectedIndex = 1
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		userNameLabel.becomeFirstResponder()

		// Do any additional setup after loading the view.
	}
}
