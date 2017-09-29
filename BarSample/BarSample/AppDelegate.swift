//
//  AppDelegate.swift
//  BarSample
//
//  Created by Sergey Galezdinov on 13.08.16.
//
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        _ = navigationBarSwizzle
        UINavigationBar.appearance().barTintColor = UIColor.gray
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let events = event?.allTouches, let touch = events.first else { return }

        guard let level = touch.window?.windowLevel, level <= UIWindowLevelStatusBar else { return }

        let location = touch.location(in: self.window)
        let statusBarFrame = UIApplication.shared.statusBarFrame
        if statusBarFrame.contains(location) || location.y < 40 {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "statusBarTouched"), object: nil)
        }
    }

}

