//
//  ViewController.swift
//  Presenter
//
//  Created by Jaeyoung Choi on 2017. 6. 5..
//  Copyright © 2017년 Appcid. All rights reserved.
//

import UIKit
import UIXPresenter

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let button = UIButton(type: .system)
        button.setTitle("Show", for: .normal)
        button.addTarget(self, action: #selector(showOverlay(sender:)), for: .touchUpInside)
        view.addSubview(button)
        button.centerToSuperview()
    }
    
    func showOverlay(sender: Any) {
        let overlayVC = UIXOverlayViewController()
        presentCustom(overlayVC, animated: true, completion: nil)
    }

}

