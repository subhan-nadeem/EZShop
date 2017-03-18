//
//  AppDelegate.swift
//  ezshopUser
//
//  Created by Jung Geon Choi on 2017-03-18.
//  Copyright © 2017 Jung Geon Choi. All rights reserved.
//

import UIKit
import Firebase
//import FirebaseMessaging
import UserNotifications
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, FIRMessagingDelegate{

	var window: UIWindow?
	func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
		let token = FIRInstanceID.instanceID().token()!
		print(token)
	}

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		FIRApp.configure()

		if #available(iOS 10.0, *) {
			// For iOS 10 display notification (sent via APNS)
			UNUserNotificationCenter.current().delegate = self

			let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
			UNUserNotificationCenter.current().requestAuthorization(
    options: authOptions,
    completionHandler: {_, _ in })

			// For iOS 10 data message (sent via FCM)
			FIRMessaging.messaging().remoteMessageDelegate = self

		} else {
			let settings: UIUserNotificationSettings =
				UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
			application.registerUserNotificationSettings(settings)
		}

		application.registerForRemoteNotifications()

		NotificationCenter.default.addObserver(forName: NSNotification.Name.firInstanceIDTokenRefresh, object: nil, queue: OperationQueue.main) { (n) in
			self.tokenRefreshNotification(n)
		}
		// Override point for customization after application launch.
		return true
	}

	func tokenRefreshNotification(_ notification: Notification) {
  if let refreshedToken = FIRInstanceID.instanceID().token() {
	print("InstanceID token: \(refreshedToken)")

  }

  // Connect to FCM since connection may have failed when attempted before having a token.
  connectToFcm()
	}

	func connectToFcm() {
  // Won't connect since there is no token
  guard FIRInstanceID.instanceID().token() != nil else {
	return
  }

  // Disconnect previous FCM connection if it exists.
  FIRMessaging.messaging().disconnect()

  FIRMessaging.messaging().connect { (error) in

	if error != nil {
		print("Unable to connect with FCM. \(error)")
	} else {
		print("Connected to FCM.")
	}
  }
	}




	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let tokenChars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
		var tokenString = ""
		for i in 0..<deviceToken.count {
			tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
		}

		print("Device Token:", tokenString)

		FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)

//		 connectToFcm()
	}


	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}

	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
  // If you are receiving a notification message while your app is in the background,
  // this callback will not be fired till the user taps on the notification launching the application.
  // TODO: Handle data of notification


  // Print full message.
  print(userInfo)
	}

	func application(application: UIApplication,
	                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
  FIRInstanceID.instanceID().setAPNSToken(deviceToken as Data, type: FIRInstanceIDAPNSTokenType.sandbox)
	}

	func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
		// Let FCM know about the message for analytics etc.
		FIRMessaging.messaging().appDidReceiveMessage(userInfo)
		// handle your message
	}


	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
	                 fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
  // If you are receiving a notification message while your app is in the background,
  // this callback will not be fired till the user taps on the notification launching the application.
  // TODO: Handle data of notification


  // Print full message.
  print(userInfo)

  completionHandler(UIBackgroundFetchResult.newData)
	}



}

