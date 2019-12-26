//
//  AppDelegate.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/17.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        CustomNotificationManager.shared.setup()
        return true
    }
}

extension AppDelegate {
    func applicationDidEnterBackground(_ application: UIApplication) {
        CustomNotificationManager.shared.notify(.enterBackground)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        CustomNotificationManager.shared.notify(.enterForeground, callback: .init(resolve: { data in
            if let data = data {
                print(data)
            }
        }, reject: {error in
            if let e = error {
                print("Error: code \(e.code), msg \(e.msg)")
            }
        }))
    }
}

