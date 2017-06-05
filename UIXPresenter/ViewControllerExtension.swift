//
//  ViewControllerExtension.swift
//  UIXPresenter
//
//  Created by Jaeyoung Choi on 2017. 6. 5..
//  Copyright © 2017년 Appcid. All rights reserved.
//

import UIKit

extension UIViewController {
    public func presentCustom(_ viewControllerToPresent: UIViewController, animated flag: Bool, statusBarHidden: Bool? = nil, completion: (() -> Void)?) {
        if let vc = viewControllerToPresent as? UIXOverlayViewController {
            presentOverlayViewController(vc, animated: flag, statusBarHidden: statusBarHidden, completion: completion)
        } else {
            present(viewControllerToPresent, animated: flag, completion: completion)
        }
    }
    
    fileprivate func presentOverlayViewController(_ viewControllerToPresent: UIXOverlayViewController, animated flag: Bool, statusBarHidden: Bool? = nil, completion: (() -> Void)?) {
        transitioningDelegate = UIXOverlayTransitioningDelegate.shared
        viewControllerToPresent.transitioningDelegate = transitioningDelegate
        
        if let statusBarHidden = statusBarHidden {
            viewControllerToPresent.statusBarHidden = statusBarHidden
        } else {
            viewControllerToPresent.statusBarHidden = self.prefersStatusBarHidden
        }
        
        self.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
}
