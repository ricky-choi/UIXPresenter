//
//  UIXOverlayTransitioningDelegate.swift
//  UIXPresenter
//
//  Created by Jaeyoung Choi on 2017. 6. 5..
//  Copyright © 2017년 Appcid. All rights reserved.
//

import UIKit

class UIXOverlayTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    static let shared = UIXOverlayTransitioningDelegate()
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return UIXOverlayPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animationController = UIXOverlayAnimatedTransitioning()
        animationController.isPresentation = true
        
        return animationController
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let _ = dismissed as? UIXOverlayViewController {
            let animationController = UIXOverlayAnimatedTransitioning()
            animationController.isPresentation = false
            
            return animationController
        }
        
        return nil
    }
}
