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
    @IBOutlet var tapToReturnToCallLabel: UILabel!

    private var isBarVisible = false {
        didSet {
            guard isBarVisible != oldValue else { return }

            self.callBarView.hidden = !self.isBarVisible || self.shouldHideCallBar()

            barHeightConstraint.constant = isBarVisible ? 40 : 0
            topContainerConstraint.constant = isBarVisible && !self.shouldHideCallBar() ? 20 : 0

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

    private func shouldHideCallBar() -> Bool {
        return isSystemInCallBarVisible() || self.traitCollection.horizontalSizeClass != .Compact
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

    // MARK: blink animation
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.blinkOn()
    }

    private func blinkOn() {
        let animationOptions: UIViewAnimationOptions = [.CurveEaseInOut, .AllowUserInteraction]
        UIView.animateWithDuration(1, delay: 0.0, options: animationOptions, animations: {
            self.tapToReturnToCallLabel.alpha = 1
        }, completion: { _ in
            self.blinkOff()
        })

    }

    private func blinkOff() {
        let animationOptions: UIViewAnimationOptions = [.CurveEaseInOut, .AllowUserInteraction]
        UIView.animateWithDuration(0.8, delay: 0.4, options: animationOptions, animations: {
            self.tapToReturnToCallLabel.alpha = 0.01
        }, completion: { _ in
            self.blinkOn()
        })
    }

    // MARK: Segue

    private weak var containedTabbarController: UITabBarController?

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier == "EmbedTabbar" {
            containedTabbarController = segue.destinationViewController as? UITabBarController

            let dest = segue.destinationViewController as? UITabBarController
            let firstVCNavC = dest?.viewControllers?.first as? UINavigationController
            let firstVC = firstVCNavC?.topViewController as? FirstViewController

            let closure: BarShowClosure = { [weak self] show in
                self?.isBarVisible = show
                if (self?.shouldHideCallBar() ?? false) {
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

    // MARK: Rotation

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {

        let navController = containedTabbarController?.selectedViewController as? UINavigationController

        // if we're going to rotate to landscape on iPhone, or iPad with 1/3 - we need to hide call bar
        if size.width > size.height && self.traitCollection.horizontalSizeClass == .Compact {
            self.wasBarVisible = self.isBarVisible
            self.isBarVisible = false
        }

        // if we return to portrait - we'll need a little hack to prevent navigationBar from downsizing
        if size.height > size.width && self.traitCollection.verticalSizeClass == .Compact {
            navController?.navigationBar.preventSizing = true
        }
        coordinator.animateAlongsideTransition(nil) { _ in

            navController?.navigationBar.preventSizing = false

            // after rotation is done to portrait - show call bar if it was hidden
            if self.wasBarVisible && !self.shouldHideCallBar() {
                let show = self.wasBarVisible
                self.wasBarVisible = false
                self.isBarVisible = show
            }

        }

        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
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
