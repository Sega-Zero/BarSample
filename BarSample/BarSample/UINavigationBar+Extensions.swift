//
//  UINavigationBar+Extensions.swift
//  BarSample
//
//  Created by Sergey Galezdinov on 14.08.16.
//
//

import UIKit

extension UINavigationBar {
    private struct AssociatedDataKey {
        static var preventSizingKey = "preventSizing"
    }

    public var preventSizing: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedDataKey.preventSizingKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedDataKey.preventSizingKey,
                newValue as Bool,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private struct SwizzleStatic {
        static var token: dispatch_once_t = 0
    }

    public override class func initialize() {
        if self !== UINavigationBar.self {
            return
        }

        func swizzle(originalSelector: Selector, swizzledSelector: Selector) {
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)

            let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))

            if didAddMethod {
                class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }

        dispatch_once(&SwizzleStatic.token) {
            swizzle(#selector(UINavigationBar.sizeThatFits(_:)), swizzledSelector: #selector(UINavigationBar.swizzled_sizeThatFits(_:)))
        }
    }

    // MARK: - Method Swizzling

    public func swizzled_sizeThatFits(size: CGSize) -> CGSize {
        var superSize = self.swizzled_sizeThatFits(size)
        if preventSizing {
            superSize.height = 64
        }
        
        return superSize
    }
}