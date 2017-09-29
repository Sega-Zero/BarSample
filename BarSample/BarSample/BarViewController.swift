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
    @IBOutlet var containerTopConstraint: NSLayoutConstraint!

    private var isBarVisible = false {
        didSet {
            guard isBarVisible != oldValue else { return }

            barHeightConstraint.constant = isBarVisible && !self.shouldHideCallBar() ? callBarHeight() : 0
            if #available(iOS 11, *) {
                containerTopConstraint.constant = barHeightConstraint.constant
            }
            UINavigationBar.ExtraSize.additionalHeight = isBarVisible && !self.shouldHideCallBar() ? self.callBarHeight() - 20 : 0

            self.showCallBarAnimated()
        }
    }

    // MARK: private methods

    func callBarHeight() -> CGFloat {
        return UIApplication.shared.statusBarFrame.height + (self.isSystemInCallBarVisible() ? 0 : 20)
    }

    private func isSystemInCallBarVisible() -> Bool {
        let statusBarFrame = UIApplication.shared.statusBarFrame
        return statusBarFrame.height > 20
    }

    private func shouldHideCallBar() -> Bool {
        return false//always display bar
    }

    private func updateNavigationBar(_ forViewController: UIViewController?) {
        if let navC = forViewController?.navigationController {
            self.updateNavigationBar(navC)
        }
        if let tabbarController = forViewController as? UITabBarController, let selectedVC = tabbarController.selectedViewController {
            self.updateNavigationBar(selectedVC)
        }
        if let splitViewController = forViewController as? UISplitViewController {
            splitViewController.viewControllers.forEach { self.updateNavigationBar($0) }
        }
        if let navigationController = forViewController as? UINavigationController {
            navigationController.navigationBar.sizeToFit()

            if let topViewController = navigationController.topViewController {
                func updateNavigationBars(_ onView: UIView) {
                    for view in onView.subviews {
                        if let navBar = view as? UINavigationBar {
                            navBar.sizeToFit()
                        } else {
                            updateNavigationBars(view)
                        }
                    }
                }

                updateNavigationBars(topViewController.view)
                topViewController.view.setNeedsLayout()
                topViewController.view.layoutIfNeeded()

                topViewController.childViewControllers.forEach {
                    $0.view.setNeedsLayout()
                    $0.view.layoutIfNeeded()
                }
            }
        }
    }

    private func showCallBarAnimated() {
        UIView.transition(with: self.callBarView, duration: 0.3, options: [UIViewAnimationOptions.transitionFlipFromTop, UIViewAnimationOptions.layoutSubviews, UIViewAnimationOptions.curveEaseOut], animations: {
            self.view.layoutIfNeeded()
            self.updateNavigationBar(self.containedTabbarController)
        }, completion: nil)
    }

    // MARK: LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).statusBarFrameWillChange), name: Notification.Name.UIApplicationWillChangeStatusBarFrame, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).statusBarFrameDidChange), name: Notification.Name.UIApplicationDidChangeStatusBarFrame, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).statusBarTouched), name: Notification.Name(rawValue: "statusBarTouched"), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private var shouldAutoRotateOnIPad = false

    // MARK: Blink animation

    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        shouldAutoRotateOnIPad = true
        super.viewDidAppear(animated)
        self.blinkOn()

        UIApplication.shared.setStatusBarHidden(false, with: .none)
    }

    private func blinkOn() {
        let animationOptions: UIViewAnimationOptions = .allowUserInteraction
        UIView.animate(withDuration: 1, delay: 0.0, options: animationOptions, animations: { [weak self] in
            self?.tapToReturnToCallLabel.alpha = 1
            }, completion: {  [weak self] _ in
                self?.blinkOff()
        })

    }

    private func blinkOff() {
        let animationOptions: UIViewAnimationOptions = .allowUserInteraction
        UIView.animate(withDuration: 0.8, delay: 0.4, options: animationOptions, animations: { [weak self] in
            self?.tapToReturnToCallLabel.alpha = 0.01
            }, completion: {  [weak self] _ in
                self?.blinkOn()
        })
    }

    // MARK: Segue

    private weak var containedTabbarController: UITabBarController?

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier == "EmbedTabbar" {
            containedTabbarController = segue.destination as? UITabBarController

            let dest = segue.destination as? UITabBarController
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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        barHeightConstraint.constant = isBarVisible && !self.shouldHideCallBar() ? callBarHeight() : 0

        // if we're going to rotate to landscape on iPhone - we need to hide call bar
        if size.width > size.height && self.traitCollection.horizontalSizeClass == .compact && self.traitCollection.userInterfaceIdiom == .phone {
            barHeightConstraint.constant = 0
            UINavigationBar.ExtraSize.additionalHeight = 0
        }

        if size.height > size.width && self.traitCollection.verticalSizeClass == .compact {
            barHeightConstraint.constant = isBarVisible ? callBarHeight() + 20 : 0
            UINavigationBar.ExtraSize.additionalHeight = isBarVisible ? self.callBarHeight() : 0
        }

        coordinator.animate(alongsideTransition: { _ in
            let screenBounds = UIApplication.shared.windows.first?.bounds ?? self.view.frame
            if self.view.frame != screenBounds {
                self.view.frame = screenBounds
            }
            self.view.layoutIfNeeded()

            UIApplication.shared.setStatusBarHidden(false, with: .none)
        }) { _ in

            self.barHeightConstraint.constant = self.isBarVisible && !self.shouldHideCallBar() ? self.callBarHeight() : 0
            UINavigationBar.ExtraSize.additionalHeight = self.isBarVisible && !self.shouldHideCallBar() ? self.callBarHeight() - 20 : 0

            //animate size since In-Call bar may gone during landscape, so we'll need a smooth resize
            UIView.animate(withDuration: 0.2, animations: {
                self.updateNavigationBar(self.containedTabbarController)
            })
        }

        super.viewWillTransition(to: size, with: coordinator)
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var shouldAutorotate: Bool {
        guard self.traitCollection.userInterfaceIdiom != .pad else { return shouldAutoRotateOnIPad }
        return containedTabbarController?.shouldAutorotate ?? true
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        guard self.traitCollection.userInterfaceIdiom != .pad else { return super.preferredInterfaceOrientationForPresentation }
        return containedTabbarController?.preferredInterfaceOrientationForPresentation ?? .portrait
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard self.traitCollection.userInterfaceIdiom != .pad else { return super.supportedInterfaceOrientations }
        return containedTabbarController?.supportedInterfaceOrientations ?? .allButUpsideDown
    }

    // MARK: Notifications

    @objc private func statusBarFrameWillChange(_ notification: Notification) {
        guard let newFrameValue = notification.userInfo?[UIApplicationStatusBarFrameUserInfoKey] as? NSValue else { return }

        let newFrame = newFrameValue.cgRectValue

        if newFrame.height > 20 {
            barHeightConstraint.constant = isBarVisible && !self.shouldHideCallBar()  ? callBarHeight() : 0
            UINavigationBar.ExtraSize.additionalHeight = isBarVisible && !self.shouldHideCallBar() ? self.callBarHeight() - 20 : 0
            self.updateNavigationBar(self.containedTabbarController)
        }
    }

    @objc private func statusBarFrameDidChange(_ notification: Notification) {
        guard let oldFrameValue = notification.userInfo?[UIApplicationStatusBarFrameUserInfoKey] as? NSValue else { return }

        let oldFrame = oldFrameValue.cgRectValue

        if oldFrame.height > 20 {
            barHeightConstraint.constant = isBarVisible && !self.shouldHideCallBar() ? callBarHeight() : 0
            UINavigationBar.ExtraSize.additionalHeight = isBarVisible && !self.shouldHideCallBar() ? self.callBarHeight() - 20 : 0
            self.updateNavigationBar(self.containedTabbarController)
        }
    }

    @objc private func statusBarTouched(_ notification: Notification) {
        print("user tapped on statusbar")
        if self.isBarVisible && !self.shouldHideCallBar() {
            self.callbarTap(sender: self)
        }
    }

    //MARK: Actions

    @IBAction func callbarTap(sender: AnyObject) {
        print("tapped on call bar")
    }

}
