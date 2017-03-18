//
//  JGUtils.swift
//  emii
//
//  Created by Jung Geon Choi on 2017-03-04.
//  Copyright © 2017 Emanant Inc. All rights reserved.
//

import Foundation
import SwiftyJSON
import UIKit

class JGUtils {
	// MARK: - Variables
	static var vc: UIViewController {
		get {
			if var topController = UIApplication.shared.keyWindow?.rootViewController {
				while let presentedViewController = topController.presentedViewController {
					topController = presentedViewController
				}
				return topController
			}
			print("Failed to find first view controller @ JGUtils.getFrontViewController()")
			return UIViewController()
		}

	}


	// MARK: - Alert ONLY
	static func alert(title: String, message: String?, buttonMessage: String = "OK") {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: buttonMessage, style: .cancel, handler: nil))
		vc.present(alert, animated: true, completion: nil)
	}

	// MARK: - Selection Alert
}

// MARK: - View Extension
extension UIView {
	var animationDuration: TimeInterval {
		get {
			return 0.5
		}
	}

	func hide() {
		self.alpha = 1.0
		UIView.animate(withDuration: animationDuration) {
			self.alpha = 0.0
		}

	}

	func show() {
		self.alpha = 0.0
		UIView.animate(withDuration: animationDuration) { 
			self.alpha = 1.0
		}
	}
}

extension JSON {
	func hasError() -> Bool {
		let error = self["error"]["message"].stringValue
		return !error.isEmpty
	}

	var errorMessage: String {
		get {
			return self["error"]["message"].stringValue
		}
	}
}

// MARK: - Statusbard Indicator

extension JGUtils {
	static func setNetworkIndicator(_ status: Bool) {
		UIApplication.shared.isNetworkActivityIndicatorVisible = status
	}
}

extension UIColor {
	static public var tint: UIColor {
		return UIColor(
			red: CGFloat(73.0/255.0),
			green: CGFloat(188.0/255.0),
			blue: CGFloat(167.0/255.0),
			alpha: CGFloat(1.0)
		)
	}
}

// MARK: - String
extension String {

	var formattedPhoneNumber: String {
		return "(" + self[0..<3] + ") " + self[3..<6] + "-" + self[6..<10]
	}

	var length: Int {
		return self.characters.count
	}

	subscript (i: Int) -> String {
		return self[Range(i ..< i + 1)]
	}

	func substring(from: Int) -> String {
		return self[Range(min(from, length) ..< length)]
	}

	func substring(to: Int) -> String {
		return self[Range(0 ..< max(0, to))]
	}

	subscript (r: Range<Int>) -> String {
		let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
		                                    upper: min(length, max(0, r.upperBound))))
		let start = index(startIndex, offsetBy: range.lowerBound)
		let end = index(start, offsetBy: range.upperBound - range.lowerBound)
		return self[Range(start ..< end)]
	}

}

// MARK: - Notification
extension Notification.Name {
	static let tokenReceivedFromWeb = Notification.Name("ReceivedTokenFromWeb")
}

