//
//  UIXOverlayPresentationController.swift
//  UIXPresenter
//
//  Created by Jaeyoung Choi on 2017. 6. 5..
//  Copyright © 2017년 Appcid. All rights reserved.
//

import UIKit

class UIXOverlayPresentationController: UIPresentationController {
    var dimmingView: UIView?
    var overlayY: CGFloat?
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        if let presented = presentedViewController as? UIXOverlayViewController , presented.showDimmingView {
            prepareDimmingView(presented.dimmingColor)
        }
    }
    
    override func presentationTransitionWillBegin() {
        guard let container = containerView, let dimmingView = dimmingView else {
            return
        }
        
        dimmingView.frame = container.bounds
        container.insertSubview(dimmingView, at: 0)
        
        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { _ in
                dimmingView.alpha = 1.0
            }, completion: nil)
        } else {
            dimmingView.alpha = 1.0
        }
    }
    
    override func dismissalTransitionWillBegin() {
        guard let dimmingView = dimmingView else {
            return
        }
        
        if let transitionCoordinator = presentedViewController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: { _ in
                dimmingView.alpha = 0.0
            }, completion: nil)
        } else {
            dimmingView.alpha = 0.0
        }
    }
    
    override var adaptivePresentationStyle : UIModalPresentationStyle {
        return .overFullScreen
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        guard let viewController = presentedViewController as? UIXOverlayViewController else {
            return CGSize(width: 0, height: 0)
        }
        
        switch viewController.overlayType {
        case .staticRatio(let ratio):
            return CGSize(width: parentSize.width, height: parentSize.height * ratio)
        case .staticValue(let height):
            return CGSize(width: parentSize.width, height: height)
        case .dynamicRatio(let maxRatio, _):
            return CGSize(width: parentSize.width, height: parentSize.height * maxRatio)
        case .dynamicValue(let maxHeight, _):
            return CGSize(width: parentSize.width, height: maxHeight)
        }
    }
    
    override func containerViewWillLayoutSubviews() {
        guard let container = containerView else {
            return
        }
        
        dimmingView?.frame = container.bounds
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override var shouldPresentInFullscreen : Bool {
        return true
    }
    
    override var frameOfPresentedViewInContainerView : CGRect {
        guard let container = containerView, let viewController = presentedViewController as? UIXOverlayViewController else {
            return CGRect.zero
        }
        
        var presentedViewFrame = CGRect.zero
        let containerBounds = container.bounds
        
        presentedViewFrame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerBounds.size)
        
        if let y = overlayY {
            presentedViewFrame.origin.y = y
        } else {
            switch viewController.overlayType {
            case .staticRatio(let ratio):
                let recommendedHeight = containerBounds.size.height * ratio
                presentedViewFrame.origin.y = containerBounds.size.height - recommendedHeight
            case .staticValue(let height):
                presentedViewFrame.origin.y = containerBounds.size.height - height
            case .dynamicRatio(_, let recommendedRatio):
                let recommendedHeight = containerBounds.size.height * recommendedRatio
                presentedViewFrame.origin.y = containerBounds.size.height - recommendedHeight
            case .dynamicValue(_, let recommendedHeight):
                presentedViewFrame.origin.y = containerBounds.size.height - recommendedHeight
            }
            
        }
        
        return presentedViewFrame
    }
    
    func prepareDimmingView(_ dimmColor: UIColor) {
        let dimmingView: UIView
        
        dimmingView = UIView()
        dimmingView.backgroundColor = dimmColor
        dimmingView.alpha = 0.0
        
        var dismissWhenTapDimmingView: Bool = true
        if let viewController = presentedViewController as? UIXPresenter {
            dismissWhenTapDimmingView = viewController.dismissWhenTapDimmingView
        }
        
        if dismissWhenTapDimmingView {
            let tap = UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped(_:)))
            dimmingView.addGestureRecognizer(tap)
        }
        
        self.dimmingView = dimmingView
    }
    
    @objc func dimmingViewTapped(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .recognized {
            presentingViewController.dismiss(animated: true, completion: nil)
        }
    }
}
