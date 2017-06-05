//
//  UIXOverlayView.swift
//  UIXPresenter
//
//  Created by Jaeyoung Choi on 2017. 6. 5..
//  Copyright © 2017년 Appcid. All rights reserved.
//

import UIKit

class UIXOverlayView: UIView {

    var extendView: UIView?
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        if let extendView = extendView {
            let pointForExtendView = extendView.convert(point, from: self)
            if extendView.bounds.contains(pointForExtendView) {
                return extendView.hitTest(pointForExtendView, with: event)
            }
        }
        
        return super.hitTest(point, with: event)
    }

}
