//
//  UINavigationBar+Extensions.swift
//  BarSample
//
//  Created by Sergey Galezdinov on 14.08.16.
//
//

import UIKit

private let swizzleClosure: (UINavigationBar.Type) -> Void = { navBar in

    func swizzle(selector: Selector, to swizzledSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(navBar, selector), let swizzledMethod = class_getInstanceMethod(navBar, swizzledSelector) else { return }

        let didAddMethod = class_addMethod(navBar, selector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))

        if didAddMethod {
            class_replaceMethod(navBar, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    swizzle(selector: #selector(UINavigationBar.sizeThatFits(_:)), to: #selector(UINavigationBar.swizzled_sizeThatFits(_:)))
}

let navigationBarSwizzle: () = swizzleClosure(UINavigationBar.self)

/// :nodoc:
extension UINavigationBar {
    private struct AssociatedDataKey {
        static var preventSizingKey = "preventSizing"
    }

    struct ExtraSize {
        static var additionalHeight: CGFloat = 0
    }

    // MARK: - Method Swizzling

    @objc public func swizzled_sizeThatFits(_ size: CGSize) -> CGSize {
        var superSize = self.swizzled_sizeThatFits(size)

        if type(of: self).ExtraSize.additionalHeight != 0 {
            let owner = self.firstAvailableUIViewController()
            if owner?.presentingViewController == nil {
                superSize.height += type(of: self).ExtraSize.additionalHeight
            }
        }

        return superSize
    }
}

private extension UIView {
    func firstAvailableUIViewController() -> UIViewController? {
        return traverseResponderChainForUIViewController() as? UIViewController
    }
    func traverseResponderChainForUIViewController() -> AnyObject? {
        let nextResponder = self.next
        switch nextResponder {
        case let vc? where vc is UIViewController:
            return vc
        case let view? where view is UIView:
            return (view as? UIView)?.traverseResponderChainForUIViewController()
        default:
            return nil
        }
    }
}
