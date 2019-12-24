//
//  ViewController.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/17.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    
    @IBAction func goWeb(_ sender: Any) {
        navigationController?.pushViewController(MainWebController.default, animated: true)
    }
}
