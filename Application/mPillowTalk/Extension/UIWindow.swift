//
//  UIWindow.swift
//  mPillowTalk
//
//  Created by Lakr Aream on 4/28/21.
//

import UIKit

extension UIWindow {
    var topMostViewController: UIViewController? {
        var viewController: UIViewController?
        viewController = rootViewController
        while let childViewController = viewController?.presentedViewController {
            viewController = childViewController
        }
        return viewController
    }
}
