//
//  MainWebController.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/19.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import UIKit

class MainWebController: CommonWebController {
    
    static let `default` = MainWebController(.main)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Main"
        addReloadButton()
        start()
    }
}
