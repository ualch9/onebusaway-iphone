//
//  OBAApp.swift
//  OneBusAway
//
//  Created by Alan Chu on 8/11/19.
//  Copyright © 2019 OneBusAway. All rights reserved.
//

import UIKit

@UIApplicationMain
class OBAApp: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		self.window = UIWindow(frame: UIScreen.main.bounds)
		let regionSelection = UINavigationController(rootViewController: RegionsViewController())
		
		let pages = UITabBarController()
		pages.setViewControllers([regionSelection], animated: true)
		
		self.window?.rootViewController = pages
		self.window?.makeKeyAndVisible()
		
		return true
	}
}
