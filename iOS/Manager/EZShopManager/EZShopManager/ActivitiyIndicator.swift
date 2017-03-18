//
//  ActivitiyIndicator.swift
//  emii
//
//  Created by Jung Geon Choi on 2017-03-04.
//  Copyright © 2017 Emanant Inc. All rights reserved.
//
import Foundation
import UIKit

class ActivityIndicator {
	static let shared = ActivityIndicator()

	var blurEffect = UIBlurEffect()
	var backgroundView = UIView()
	var blurEffectView = UIVisualEffectView()
	var loadingIndicator = UIActivityIndicatorView()
	var myCover = UIView()
	let labelText=UILabel()

	init () {
		// make background blur
		blurEffect = UIBlurEffect(style: UIBlurEffectStyle.extraLight)
		blurEffectView = UIVisualEffectView(effect: blurEffect)

		// make activity indicator
//		backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
		loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))

	}

	func show(_ view: UIView) {
		blurEffectView.frame = view.bounds
//		backgroundView.frame = view.bounds
		loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
		loadingIndicator.hidesWhenStopped = true
		loadingIndicator.startAnimating()
		loadingIndicator.center = view.center
		loadingIndicator.color = view.tintColor
//		view.addSubview(backgroundView)
		view.addSubview(blurEffectView)
		view.addSubview(loadingIndicator)
//		labelText.frame=CGRect(x: 0,y: loadingIndicator.center.y+40,width: view.frame.width,height: 20)
//		labelText.text="Loading..."
//		labelText.textAlignment=NSTextAlignment.center
//		labelText.textColor=UIColor.white
//		view.addSubview(labelText)
		blurEffectView.show()
		loadingIndicator.show()

	}

	func hide() {
		blurEffectView.hide()
		loadingIndicator.hide()

		blurEffectView.removeFromSuperview()
		loadingIndicator.removeFromSuperview()
//		myCover.removeFromSuperview()
//		backgroundView.removeFromSuperview()

//		labelText.removeFromSuperview()
	}
}
