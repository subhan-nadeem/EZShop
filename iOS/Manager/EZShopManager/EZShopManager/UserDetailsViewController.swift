//
//  UserDetailsViewController.swift
//  EZShopManager
//
//  Created by Jung Geon Choi on 2017-03-18.
//  Copyright © 2017 Jung Geon Choi. All rights reserved.
//

import UIKit

extension UserDetailsViewController: UserTableDelgate {
	func didSelectUser(user: User) {
		self.user = user
		reloadPage()
	}
}

class UserDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	var user: User = User()
	@IBOutlet weak var userImageView: UIImageView!
	@IBOutlet weak var userNameLabel: UILabel!
	@IBOutlet weak var userStatusLabel: UILabel!
	@IBOutlet weak var userStatusCircle: UIView!
	@IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
		tableView.tableFooterView = UIView()
		userStatusCircle.clipsToBounds = true
		userStatusCircle.layer.cornerRadius = userStatusCircle.frame.width / 2
		userImageView.clipsToBounds = true
		userImageView.layer.cornerRadius = userImageView.frame.width / 2

        // Do any additional setup after loading the view.
    }

	func reloadPage() {
		userNameLabel.text = user.name
		userImageView.kf.setImage(with: URL(string: user.photo))
		userStatusLabel.text = user.isInStore ? "In Store" : "Not In Store"
		userStatusCircle.backgroundColor = user.isInStore ? UIColor.green : UIColor.red
		tableView.reloadData()
		cartCover.removeFromSuperview()
		if user.items.count == 0 {
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



	 func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
var cartCover = UIView()
	 func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		return user.isInStore ? user.items.count : 0
	}



	 func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
		let item = user.items[indexPath.row]
		cell.textLabel?.text = item.item_name
		cell.detailTextLabel?.text = "$ \(item.item_price)"


		return cell
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
