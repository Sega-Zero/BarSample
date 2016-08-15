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
    @IBOutlet var tapToReturnToCallLabel: UILabel!

    private var isBarVisible = false {
        didSet {
            guard isBarVisible != oldValue else { return }

            barHeightConstraint.constant = isBarVisible && !self.shouldHideCallBar() ? callBarHeight() : 0
            UINavigationBar.ExtraSize.additionalHeight = isBarVisible && !self.shouldHideCallBar() ? self.callBarHeight() - 20 : 0

            self.showCallBarAnimated()
        }
    }

    // MARK: private methods

    func callBarHeight() -> CGFloat {
        return UIApplication.sharedApplication().statusBarFrame.height + (self.isSystemInCallBarVisible() ? 0 : 20)
    }

    private func isSystemInCallBarVisible() -> Bool {
        let statusBarFrame = UIApplication.sharedApplication().statusBarFrame
        return statusBarFrame.height > 20
    }

    private func shouldHideCallBar() -> Bool {
        return self.traitCollection.verticalSizeClass == .Compact
    }

    private func showCallBarAnimated() {
        let navController = containedTabbarController?.selectedViewController as? UINavigationController
        UIView.transitionWithView(self.callBarView, duration: 0.3, options: [UIViewAnimationOptions.TransitionFlipFromTop, UIViewAnimationOptions.LayoutSubviews, UIViewAnimationOptions.CurveEaseOut], animations: {
            self.view.layoutIfNeeded()
            navController?.navigationBar.sizeToFit()
            }, completion: nil)
    }

    // MARK: LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dynamicType.statusBarFrameWillChange), name: UIApplicationWillChangeStatusBarFrameNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dynamicType.statusBarFrameDidChange), name: UIApplicationDidChangeStatusBarFrameNotification, object: nil)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.dynamicType.statusBarTouched), name: "statusBarTouched", object: nil)
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
            }

            firstVC?.barClosure = closure
            let secondVCNavC = dest?.viewControllers?.last as? UINavigationController
            let secondVC = secondVCNavC?.topViewController as? SecondViewController
            secondVC?.barClosure = closure
        }
    }

    // MARK: Rotation

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {

        barHeightConstraint.constant = isBarVisible && !self.shouldHideCallBar() ? callBarHeight() : 0

        // if we're going to rotate to landscape on iPhone - we need to hide call bar
        if size.width > size.height && self.traitCollection.horizontalSizeClass == .Compact && self.traitCollection.userInterfaceIdiom == .Phone {
            barHeightConstraint.constant = 0
            UINavigationBar.ExtraSize.additionalHeight = 0
        }

        let navController = containedTabbarController?.selectedViewController as? UINavigationController

        if size.height > size.width && self.traitCollection.verticalSizeClass == .Compact {
            barHeightConstraint.constant = isBarVisible ? callBarHeight() + 20 : 0
            UINavigationBar.ExtraSize.additionalHeight = isBarVisible ? self.callBarHeight() : 0
        }

        coordinator.animateAlongsideTransition({ _ in self.view.layoutIfNeeded() }) { _ in
            self.barHeightConstraint.constant = self.isBarVisible && !self.shouldHideCallBar() ? self.callBarHeight() : 0
            UINavigationBar.ExtraSize.additionalHeight = self.isBarVisible && !self.shouldHideCallBar() ? self.callBarHeight() - 20 : 0

            //animate size since In-Call bar may gone during landscape, so we'll need a smooth resize
            UIView.animateWithDuration(0.2) {
                navController?.navigationBar.sizeToFit()
            }
        }

        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }

    // MARK: Notifications

    @objc private func statusBarFrameWillChange(notification: NSNotification) {
        guard let newFrameValue = notification.userInfo?[UIApplicationStatusBarFrameUserInfoKey] as? NSValue else { return }

        let newFrame = newFrameValue.CGRectValue()

        if newFrame.height > 20 {
            barHeightConstraint.constant = isBarVisible && !self.shouldHideCallBar()  ? callBarHeight() : 0
            UINavigationBar.ExtraSize.additionalHeight = isBarVisible && !self.shouldHideCallBar() ? self.callBarHeight() - 20 : 0
            let navController = containedTabbarController?.selectedViewController as? UINavigationController
            navController?.navigationBar.sizeToFit()
        }
    }

    @objc private func statusBarFrameDidChange(notification: NSNotification) {
        guard let oldFrameValue = notification.userInfo?[UIApplicationStatusBarFrameUserInfoKey] as? NSValue else { return }

        let navController = containedTabbarController?.selectedViewController as? UINavigationController

        let oldFrame = oldFrameValue.CGRectValue()

        if oldFrame.height > 20 {
            barHeightConstraint.constant = isBarVisible && !self.shouldHideCallBar() ? callBarHeight() : 0
            UINavigationBar.ExtraSize.additionalHeight = isBarVisible && !self.shouldHideCallBar() ? self.callBarHeight() - 20 : 0
            navController?.navigationBar.sizeToFit()
        }
    }

    @objc private func statusBarTouched(notification: NSNotification) {
        self.callbarTap(self)
    }

    //MARK: Actions

    @IBAction func callbarTap(sender: AnyObject) {
        print("tapped on call bar")
    }

}
