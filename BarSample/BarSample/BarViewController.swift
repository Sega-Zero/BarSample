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

            self.callBarView.hidden = !self.isBarVisible

            barHeightConstraint.constant = isBarVisible ? 40 : 0
            topContainerConstraint.constant = isBarVisible ? 20 : 0
            
            UIView.transitionWithView(self.callBarView, duration: 0.3, options: [UIViewAnimationOptions.TransitionFlipFromTop, UIViewAnimationOptions.LayoutSubviews, UIViewAnimationOptions.CurveEaseOut], animations: { self.view.layoutIfNeeded() }) { _ in
                if !self.isBarVisible {
                    self.callBarView.hidden = true
                }
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier == "EmbedTabbar" {
            let dest = segue.destinationViewController as? UITabBarController
            let firstVCNavC = dest?.viewControllers?.first as? UINavigationController
            let firstVC = firstVCNavC?.topViewController as? FirstViewController
            firstVC?.barClosure = { [weak self] show in
                self?.isBarVisible = show
            }
            let secondVCNavC = dest?.viewControllers?.last as? UINavigationController
            let secondVC = secondVCNavC?.topViewController as? SecondViewController
            secondVC?.barClosure = { [weak self] show in
                self?.isBarVisible = show
            }
        }
    }
}
