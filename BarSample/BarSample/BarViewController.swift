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

    private var isBarVisible = false {
        didSet {
            guard isBarVisible != oldValue else { return }

            barHeightConstraint.constant = isBarVisible ? 40 : 0
            UIView.animateWithDuration(0.3) { _ in
                self.view.layoutIfNeeded()
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
