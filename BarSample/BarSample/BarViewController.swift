//
//  BarViewController.swift
//  BarSample
//
//  Created by Sergey Galezdinov on 13.08.16.
//
//

import UIKit

typealias BarShowClosure = (Bool) -> ()

class BarViewController: UIViewController {

    @IBOutlet var barHeightConstraint: NSLayoutConstraint!
    @IBOutlet var callBarView: UIView!
    @IBOutlet var topContainerConstraint: NSLayoutConstraint!

    private var isBarVisible = false {
        didSet {
            guard isBarVisible != oldValue else { return }

            self.callBarView.hidden = !self.isBarVisible || self.isSystemInCallBarVisible()

            barHeightConstraint.constant = isBarVisible ? 40 : 0
            topContainerConstraint.constant = isBarVisible && !self.isSystemInCallBarVisible() ? 20 : 0
            
            UIView.transitionWithView(self.callBarView, duration: 0.3, options: [UIViewAnimationOptions.TransitionFlipFromTop, UIViewAnimationOptions.LayoutSubviews, UIViewAnimationOptions.CurveEaseOut], animations: { self.view.layoutIfNeeded() }) { _ in
                if !self.isBarVisible {
                    self.callBarView.hidden = true
                }
            }
        }
    }

    // MARK: private methods

    private func isSystemInCallBarVisible() -> Bool {
        let statusBarFrame = UIApplication.sharedApplication().statusBarFrame
        return statusBarFrame.height > 20
    }

    // MARK: LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dynamicType.statusBarFrameWillChange), name: UIApplicationWillChangeStatusBarFrameNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dynamicType.statusBarFrameDidChange), name: UIApplicationDidChangeStatusBarFrameNotification, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: Segue

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier == "EmbedTabbar" {
            let dest = segue.destinationViewController as? UITabBarController
            let firstVCNavC = dest?.viewControllers?.first as? UINavigationController
            let firstVC = firstVCNavC?.topViewController as? FirstViewController

            let closure: BarShowClosure = { [weak self] show in
                self?.isBarVisible = show
                if (self?.isSystemInCallBarVisible() ?? false) {
                    self?.wasBarVisible = show
                    self?.isBarVisible = false
                }
            }

            firstVC?.barClosure = closure
            let secondVCNavC = dest?.viewControllers?.last as? UINavigationController
            let secondVC = secondVCNavC?.topViewController as? SecondViewController
            secondVC?.barClosure = closure
        }
    }

    // MARK: Notifications

    private var wasBarVisible = false

    @objc private func statusBarFrameWillChange(notification: NSNotification) {
        guard let newFrameValue = notification.userInfo?[UIApplicationStatusBarFrameUserInfoKey] as? NSValue else { return }

        let newFrame = newFrameValue.CGRectValue()

        if newFrame.height > 20 {
            self.wasBarVisible = self.isBarVisible
            self.isBarVisible = false
        }
    }

    @objc private func statusBarFrameDidChange(notification: NSNotification) {
        guard let oldFrameValue = notification.userInfo?[UIApplicationStatusBarFrameUserInfoKey] as? NSValue else { return }

        let oldFrame = oldFrameValue.CGRectValue()

        if oldFrame.height > 20 {
            self.isBarVisible = wasBarVisible
            wasBarVisible = false
        }
    }
}
