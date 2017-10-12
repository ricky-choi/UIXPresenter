//
//  UIXOverlayViewController.swift
//  UIXPresenter
//
//  Created by Jaeyoung Choi on 2017. 6. 5..
//  Copyright © 2017년 Appcid. All rights reserved.
//

import UIKit

protocol UIXPresenter {
    var statusBarHidden: Bool { get }
    var showDimmingView: Bool { get }
    var dimmingColor: UIColor { get }
    var dismissWhenTapDimmingView: Bool { get }
}

open class UIXOverlayViewController: UIViewController, UIXPresenter {
    
    enum PresentType {
        case staticRatio(heightRatio: CGFloat)
        case dynamicRatio(maxHeightRatio: CGFloat, recommendHeightRatio: CGFloat)
        
        case staticValue(height: CGFloat)
        case dynamicValue(maxHeight: CGFloat, recommendHeight: CGFloat)
        
        var isStatic: Bool {
            switch self {
            case .staticRatio(_), .staticValue(_):
                return true
            default:
                return false
            }
        }
        var isDynamic: Bool {
            return !isStatic
        }
    }
    
    enum DynamicMode {
        case max
        case recommend
    }
    
    // UIXPresenter
    var statusBarHidden: Bool = false
    var showDimmingView: Bool {
        return true
    }
    var dimmingColor: UIColor {
        return UIColor(white: 0, alpha: 0.5)
    }
    var dismissWhenTapDimmingView: Bool = true
    
    // Properties
    var overlayType = PresentType.dynamicRatio(maxHeightRatio: 0.9, recommendHeightRatio: 0.6)
    var dynamicMode = DynamicMode.recommend
    var dynamicHeight: (max: CGFloat, recommend: CGFloat) = (0, 0)
    var dynamicGestureEnabled: Bool = true
    var swipeCloseEnabled: Bool = true
    var swipeStopRecommandY: Bool = true
    var baseScrollView: UIScrollView? = nil
    
    var startFrame: CGRect = CGRect.zero
    var contentHeight: CGFloat = 0
    var keyboardHeight: CGFloat = 0
    
    weak var extendView: UIView?
    
    fileprivate weak var rubberBandView: UIView?
    
    var observeKeyboard = false {
        didSet {
            guard oldValue != observeKeyboard else {
                return
            }
            
            let notificationCenter = NotificationCenter.default
            if observeKeyboard {
                // register notification
                notificationCenter.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
                notificationCenter.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
            } else {
                // remove notification
                notificationCenter.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
                notificationCenter.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
            }
        }
    }
    
    func setup() {
        modalPresentationStyle = .custom
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    deinit {
        print("deinit \(self)")
        
        observeKeyboard = false
    }
    
    override open func loadView() {
        view = UIXOverlayView()
    }
    
    weak var pan: UIPanGestureRecognizer?
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.white
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
        
        // top shadow
        view.layer.shadowOpacity = 0.5
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let presentationController = presentationController as? UIXOverlayPresentationController, let containerView = presentationController.containerView , self.overlayType.isDynamic {
            
            switch overlayType {
            case .dynamicRatio(let maxRatio, let recommendedRatio):
                dynamicHeight = (max: containerView.frame.height * maxRatio, recommend: containerView.frame.height * recommendedRatio)
            case .dynamicValue(let maxHeight, let recommendedHeight):
                dynamicHeight = (max: maxHeight, recommend: recommendedHeight)
            default:
                fatalError()
            }
            
            adjustScrollInset()
        }
        
        addBottomRubberBand()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        removeExtendView()
    }
    
    func heightForShrink(_ containerView: UIView) -> CGFloat {
        switch self.overlayType {
        case .dynamicRatio(let maxRatio, let recommendedRatio):
            return containerView.frame.size.height * (swipeStopRecommandY ? recommendedRatio : maxRatio)
        case .dynamicValue(let maxHeight, let recommendedHeight):
            return swipeStopRecommandY ? recommendedHeight : maxHeight
        case .staticRatio(let recommendedRatio):
            return containerView.frame.size.height * recommendedRatio
        case .staticValue(let recommendedHeight):
            return recommendedHeight
        }
    }
    
    func heightForShrink() -> CGFloat {
        if let presentationController = presentationController as? UIXOverlayPresentationController, let containerView = presentationController.containerView {
            return heightForShrink(containerView)
        }
        
        return 0
    }
    
    func oddHeightForDynamicType() -> CGFloat {
        switch self.overlayType {
        case .dynamicRatio(let maxRatio, let recommendedRatio):
            if let presentationController = presentationController as? UIXOverlayPresentationController, let containerView = presentationController.containerView {
                return containerView.frame.size.height * (maxRatio - recommendedRatio)
            } else {
                return 0
            }
        case .dynamicValue(let maxHeight, let recommendedHeight):
            return maxHeight - recommendedHeight
        default:
            return 0
        }
    }
    
    override open var prefersStatusBarHidden : Bool {
        return statusBarHidden
    }
    
    let useBanding = false
    
    @objc func panGesture(_ gesture: UIPanGestureRecognizer) {
        guard let presentationController = presentationController as? UIXOverlayPresentationController else {
            return
        }
        
        pan = gesture
        
        if gesture.state == .began {
            startFrame = view.frame
        } else if gesture.state == .changed {
            let translation = gesture.translation(in: gesture.view)
            var newY = startFrame.origin.y + translation.y
            
            var containerViewFrame = CGRect.zero
            if let containerView = presentationController.containerView {
                containerViewFrame = containerView.frame
            } else {
                containerViewFrame = UIScreen.main.bounds
            }
            
            if !useBanding {
                var targetY: CGFloat = 0.0
                
                if overlayType.isStatic {
                    switch overlayType {
                    case .staticRatio(let ratio):
                        targetY = containerViewFrame.size.height * (1 - ratio) - keyboardHeight
                        
                    case .staticValue(let height):
                        targetY = containerViewFrame.size.height - height - keyboardHeight
                    default:
                        fatalError()
                    }
                } else {
                    switch overlayType {
                    case .dynamicRatio(let maxRatio, let recommendedRatio):
                        targetY = containerViewFrame.size.height * (1 - (dynamicGestureEnabled ? maxRatio : recommendedRatio))
                    case .dynamicValue(let maxHeight, let recommendedHeight):
                        targetY = containerViewFrame.size.height - (dynamicGestureEnabled ? maxHeight : recommendedHeight)
                    default:
                        fatalError()
                    }
                }
                
                if newY < targetY {
                    newY = targetY
                }
            }
            
            if !swipeCloseEnabled {
                var targetY: CGFloat = 0.0
                
                if overlayType.isStatic {
                    switch overlayType {
                    case .staticRatio(let ratio):
                        targetY = containerViewFrame.size.height * (1 - ratio) - keyboardHeight
                        
                    case .staticValue(let height):
                        targetY = containerViewFrame.size.height - height - keyboardHeight
                    default:
                        fatalError()
                    }
                } else {
                    switch overlayType {
                    case .dynamicRatio(_, let recommendedRatio):
                        targetY = containerViewFrame.size.height * (1 - recommendedRatio)
                    case .dynamicValue(_, let recommendedHeight):
                        targetY = containerViewFrame.size.height - (recommendedHeight)
                    default:
                        fatalError()
                    }
                }
                
                if newY > targetY {
                    newY = targetY
                }
            }
            
            view.frame = CGRect(x: startFrame.origin.x, y: newY, width: startFrame.size.width, height: startFrame.size.height)
            
            presentationController.overlayY = newY
        } else if gesture.state == .ended || gesture.state == .cancelled {
            let translation = gesture.translation(in: gesture.view)
            let velocity = gesture.velocity(in: gesture.view)
            
            let overlayY = startFrame.origin.y + translation.y// + velocity.y
            
            var containerViewFrame = CGRect.zero
            if let containerView = presentationController.containerView {
                containerViewFrame = containerView.frame
            } else if gesture.state == .cancelled {
                containerViewFrame = UIScreen.main.bounds
            } else {
                return // TODO: dismiss??
            }
            
            var targetY: CGFloat = 0.0
            
            if overlayType.isStatic {
                switch overlayType {
                case .staticRatio(let ratio):
                    targetY = containerViewFrame.size.height * (1 - ratio) - keyboardHeight
                case .staticValue(let height):
                    targetY = containerViewFrame.size.height - height - keyboardHeight;
                default:
                    fatalError()
                }
                
                if (overlayY >= targetY && overlayY < containerViewFrame.size.height && velocity.y > 0) || (overlayY >= containerViewFrame.size.height) {
                    if swipeCloseEnabled {
                        dismiss(animated: true, completion: nil)
                    }
                    
                    return
                }
                
            } else {
                let maxY: CGFloat;
                let recommendedY: CGFloat;
                
                switch overlayType {
                case .dynamicRatio(let maxRatio, let recommendedRatio):
                    maxY = containerViewFrame.size.height * (1 - maxRatio)
                    recommendedY = containerViewFrame.size.height * (1 - recommendedRatio)
                case .dynamicValue(let maxHeight, let recommendedHeight):
                    maxY = containerViewFrame.size.height - maxHeight
                    recommendedY = containerViewFrame.size.height - recommendedHeight
                default:
                    fatalError()
                }
                
                if dynamicGestureEnabled {
                    if swipeStopRecommandY {
                        if overlayY < maxY {
                            targetY = maxY
                            dynamicMode = .max
                        } else if overlayY >= maxY && overlayY < recommendedY {
                            if velocity.y > 0 {
                                targetY = recommendedY
                                dynamicMode = .recommend
                            } else {
                                targetY = maxY
                                dynamicMode = .max
                            }
                        } else if overlayY >= recommendedY && overlayY < containerViewFrame.size.height {
                            if velocity.y > 0 {
                                if swipeCloseEnabled {
                                    dismiss(animated: true, completion: nil)
                                }
                                return
                            } else {
                                targetY = recommendedY
                                dynamicMode = .recommend
                            }
                        } else {
                            dismiss(animated: true, completion: nil)
                            return
                        }
                    } else {
                        if overlayY < maxY {
                            targetY = maxY
                            dynamicMode = .max
                        } else if overlayY >= maxY && overlayY < containerViewFrame.size.height {
                            if velocity.y > 0 {
                                if swipeCloseEnabled {
                                    dismiss(animated: true, completion: nil)
                                }
                                return
                            } else {
                                targetY = maxY
                                dynamicMode = .max
                            }
                        } else {
                            dismiss(animated: true, completion: nil)
                            return
                        }
                    }
                } else {
                    if (overlayY < containerViewFrame.size.height && velocity.y > 0) || (overlayY >= containerViewFrame.size.height) {
                        if swipeCloseEnabled {
                            dismiss(animated: true, completion: nil)
                        }
                        return
                    } else {
                        targetY = recommendedY
                    }
                }
            }
            
            UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: velocity.y / containerViewFrame.size.height, options: [], animations: { () -> Void in
                self.view.frame = CGRect(x: self.startFrame.origin.x, y: targetY, width: self.startFrame.size.width, height: self.startFrame.size.height)
                presentationController.overlayY = targetY
            }) { finished in
                self.fitViewDidAppear()
                
                switch self.overlayType {
                case .dynamicRatio(_, _), .dynamicValue(_, _):
                    self.adjustScrollInsetForViewHeight(containerViewFrame.size.height - targetY)
                default:
                    break
                }
            }
        }
    }
    
    func moveView(targetY: CGFloat, comeplete: (() -> ())?) {
        guard let presentationController = presentationController as? UIXOverlayPresentationController else {
            return
        }
        
        var containerViewFrame = CGRect.zero
        if let containerView = presentationController.containerView {
            containerViewFrame = containerView.frame
        }
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.view.frame = CGRect(x: self.startFrame.origin.x, y: targetY, width: self.startFrame.size.width, height: self.startFrame.size.height)
            presentationController.overlayY = targetY
        }, completion: { (finished: Bool) -> Void in
            self.fitViewDidAppear()
            comeplete?()
            
            switch self.overlayType {
            case .dynamicRatio(_, _), .dynamicValue(_, _):
                self.adjustScrollInsetForViewHeight(containerViewFrame.size.height - targetY)
            default:
                break
            }
        })
    }
    
    func fitViewDidAppear() { print(#function) }
    
    func adjustScrollInsetForViewHeight(_ height: CGFloat) {
        contentHeight = height
        
        guard let scrollView = baseScrollView, let superview = scrollView.superview else {
            return
        }
        
        let origin = superview.convert(scrollView.frame.origin, to: view)
        
        let newInsetBottom = scrollView.frame.size.height + origin.y - height
        let originalScrollInset = scrollView.contentInset
        let newScrollInset = UIEdgeInsets(top: originalScrollInset.top, left: originalScrollInset.left, bottom: newInsetBottom, right: originalScrollInset.right)
        
        scrollView.contentInset = newScrollInset
        scrollView.scrollIndicatorInsets = newScrollInset
        
    }
    
    func adjustScrollInset() {
        if self.overlayType.isDynamic {
            let height: CGFloat
            switch dynamicMode {
            case .max:
                height = dynamicHeight.max
            case .recommend:
                height = dynamicHeight.recommend
            }
            adjustScrollInsetForViewHeight(height)
        }
    }
    
    func moveToMaxHeight(_ comeplete: (() -> ())? = nil) {
        guard let presentationController = presentationController as? UIXOverlayPresentationController else {
            return
        }
        
        if let pan = pan , pan.state == .began || pan.state == .changed {
            return
        }
        
        var containerViewFrame = CGRect.zero
        if let containerView = presentationController.containerView {
            containerViewFrame = containerView.frame
        }
        
        if self.overlayType.isDynamic {
            dynamicMode = .max
            self.moveView(targetY: containerViewFrame.height - dynamicHeight.max, comeplete: comeplete)
        }
    }
}

extension UIXOverlayViewController {
    @objc func keyboardWillHide(_ aNotification: Notification) {
        keyboardAnimation(aNotification, isShow: false)
    }
    
    @objc func keyboardWillShow(_ aNotification: Notification) {
        keyboardAnimation(aNotification, isShow: true)
    }
    
    func keyboardAnimation(_ aNotification: Notification, isShow: Bool) {
        let userInfo: NSDictionary = (aNotification as NSNotification).userInfo! as NSDictionary
        let keyboardFrame: CGRect = (userInfo.object(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue).cgRectValue
        
        let viewSize = view.frame.size
        view.frame = CGRect(x: 0, y: keyboardFrame.origin.y - viewSize.height, width: viewSize.width, height: viewSize.height)
        
        if isShow {
            keyboardHeight = keyboardFrame.height
        } else {
            keyboardHeight = 0
        }
    }
}

extension UIXOverlayViewController {
    func showExtendView(_ contentView: UIView, margin: UIEdgeInsets = .zero, height: CGFloat = 150, showClose: Bool = true, backgroundColor: UIColor = UIColor(white: 0, alpha: 0.4), heightOffset: CGFloat = 0) {
        
        removeExtendView()
        
        // background
        let extendView = UIView()
        extendView.backgroundColor = backgroundColor
        view.addSubview(extendView)
        extendView.translatesAutoresizingMaskIntoConstraints = false
        extendView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        extendView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        if height <= 0 {
            NSLayoutConstraint(item: extendView, attribute: .top, relatedBy: .equal, toItem: view.superview, attribute: .top, multiplier: 1, constant: -heightOffset).isActive = true
        } else {
            extendView.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        NSLayoutConstraint(item: extendView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: heightOffset).isActive = true
        
        (view as! UIXOverlayView).extendView = extendView
        
        // content
        extendView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.leadingAnchor.constraint(equalTo: extendView.leadingAnchor, constant: margin.left).isActive = true
        contentView.trailingAnchor.constraint(equalTo: extendView.trailingAnchor, constant: margin.right).isActive = true
        contentView.topAnchor.constraint(equalTo: extendView.topAnchor, constant: margin.top).isActive = true
        contentView.bottomAnchor.constraint(equalTo: extendView.bottomAnchor, constant: margin.bottom).isActive = true
        
        if showClose {
            
            // close button
            let closeButton = UIButton(type: .custom)
            closeButton.setImage(UIImage(named: "close"), for: .normal)
            let buttonInset: CGFloat = 7
            closeButton.contentEdgeInsets = UIEdgeInsets(top: buttonInset, left: buttonInset, bottom: buttonInset, right: buttonInset)
            closeButton.addTarget(self, action: #selector(extendViewCloseButtonTouched(_:)), for: .touchUpInside)
            extendView.addSubview(closeButton)
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint(item: closeButton, attribute: .top, relatedBy: .equal, toItem: extendView, attribute: .top, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: closeButton, attribute: .trailing, relatedBy: .equal, toItem: extendView, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
            
        }
        
        self.extendView = extendView
    }
    
    func removeExtendView() {
        if extendView?.superview != nil {
            extendView?.removeFromSuperview()
        }
    }
    
    @objc func extendViewCloseButtonTouched(_ sender: AnyObject) {
        removeExtendView()
    }
    
    fileprivate func addBottomRubberBand(_ color: UIColor = UIColor.white) {
        let rubberBandView = UIView()
        rubberBandView.backgroundColor = color
        view.insertSubview(rubberBandView, at: 0)
        rubberBandView.translatesAutoresizingMaskIntoConstraints = false
        rubberBandView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        rubberBandView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        rubberBandView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height).isActive = true
        NSLayoutConstraint(item: rubberBandView, attribute: .top, relatedBy: .equal, toItem: rubberBandView.superview, attribute: .bottom, multiplier: 1, constant: -1).isActive = true
        
        self.rubberBandView = rubberBandView
    }
    
    func setBottomRubberBandViewColor(_ color: UIColor?) {
        self.rubberBandView?.backgroundColor = color
    }
}

extension UIXOverlayViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
