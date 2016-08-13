//
//  FirstViewController.swift
//  BarSample
//
//  Created by Sergey Galezdinov on 13.08.16.
//
//

import UIKit

class FirstViewController: UIViewController {

    var barClosure: BarShowClosure?

    private var barVisible = false

    @IBAction func showhidebar(sender: AnyObject) {
        barVisible = !barVisible
        barClosure?(barVisible)
    }
}

