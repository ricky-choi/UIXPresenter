//
//  UIXOverlayAnimatedTransitioning.swift
//  UIXPresenter
//
//  Created by Jaeyoung Choi on 2017. 6. 5..
//  Copyright © 2017년 Appcid. All rights reserved.
//

import UIKit

class UIXOverlayAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    var isPresentation: Bool = false
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else {
            return
        }
        
        guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else {
            return
        }
        
        let fromView = fromVC.view
        let toView = toVC.view
        
        let containerView = transitionContext.containerView
        
        if isPresentation {
            containerView.addSubview(toView!)
        }
        
        let animatingVC = isPresentation ? toVC : fromVC
        let animatingView = animatingVC.view
        
        let appearedFrame = transitionContext.finalFrame(for: animatingVC)
        var dismissedFrame = appearedFrame
        dismissedFrame.origin.y += dismissedFrame.size.height
        
        let initialFrame = isPresentation ? dismissedFrame : appearedFrame
        let finalFrame = isPresentation ? appearedFrame : dismissedFrame
        
        animatingView?.frame = initialFrame
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 5.0, options: [.beginFromCurrentState], animations: { () -> Void in
            animatingView?.frame = finalFrame
        }) { finished in
            if !self.isPresentation {
                fromView?.removeFromSuperview()
            }
            transitionContext.completeTransition(true)
        }
    }

}
