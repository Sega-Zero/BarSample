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


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        UINavigationBar.appearance().barTintColor = UIColor.grayColor()
        return true
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        guard let events = event?.allTouches(), touch = events.first else { return }
        let location = touch.locationInView(self.window)
        let statusBarFrame = UIApplication.sharedApplication().statusBarFrame
        if statusBarFrame.contains(location) {
            NSNotificationCenter.defaultCenter().postNotificationName("statusBarTouched", object: nil)
        }
    }


}

