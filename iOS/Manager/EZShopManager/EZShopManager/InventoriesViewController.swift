//
//  InventoriesViewController.swift
//  EZShopManager
//
//  Created by Jung Geon Choi on 2017-03-18.
//  Copyright © 2017 Jung Geon Choi. All rights reserved.
//

import UIKit
import SwiftyJSON
import FirebaseDatabase
import Kingfisher


class InventoriesViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource {
var ref: FIRDatabaseReference!
	var items:[Item] = []
    override func viewDidLoad() {
        super.viewDidLoad()
		ref = FIRDatabase.database().reference()
		let refHandle = ref.observe(FIRDataEventType.value, with: { (snapshot) in
			let db = JSON(snapshot.value)
			//print(db["users"])

			if let _items = db["inventories"].array {
				self.items.removeAll()
				_items.forEach({ ( _itemJSON) in
					let new = Item()
					new.item_price = _itemJSON["item_price"].doubleValue
					new.item_id = _itemJSON["item_price"].intValue
					new.item_count = _itemJSON["item_count"].intValue
					new.item_name = _itemJSON["item_name"].stringValue
					new.item_description = _itemJSON["item_description"].stringValue
					new.item_image = _itemJSON["item_image"].stringValue


					self.items.append(new)

				})
				self.items.remove(at: 0)
				self.collectionView.reloadData()
			}
		})
	}
	


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
	@IBOutlet weak var collectionView: UICollectionView!
	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return items.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath)
		cell.layer.cornerRadius = 5
		cell.layer.borderWidth = 1
		let item = items[indexPath.row]
		if let imageView = cell.viewWithTag(100) as? UIImageView {
			imageView.kf.setImage(with: URL(string: item.item_image))
		}

		if let label = cell.viewWithTag(101) as? UILabel {
			label.text = item.item_name
		}

		if let label = cell.viewWithTag(102) as? UILabel {
			label.text = "$ \(item.item_price)"
		}

		if let label = cell.viewWithTag(104) as? UILabel {
			label.text = "\(item.item_count)"
		}


		return cell
	}



}
