//
//  UserDetailsViewController.swift
//  EZShopManager
//
//  Created by Jung Geon Choi on 2017-03-18.
//  Copyright © 2017 Jung Geon Choi. All rights reserved.
//

import UIKit

class UserDetailsViewController: UIViewController {
	@IBOutlet weak var userImageView: UIImageView!
	@IBOutlet weak var userNameLabel: UILabel!
	@IBOutlet weak var userStatusLabel: UILabel!
	@IBOutlet weak var userStatusCircle: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

		

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
