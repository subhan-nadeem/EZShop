import UIKit

class User {
	static var instance = User()
	var name = ""
	var photo = ""
	var user_id = ""
	var isInStore = false
	var items: [Item] = []

	static func setUserName(name: String) {
		UserDefaults.standard.set(name, forKey: "UserNameKey")
		UserDefaults.standard.synchronize()
	}

	static func getUserName() -> String {
		if UserDefaults.standard.string(forKey: "UserNameKey") == nil {
			return ""
		}
		return UserDefaults.standard.string(forKey: "UserNameKey")!
	}
}
