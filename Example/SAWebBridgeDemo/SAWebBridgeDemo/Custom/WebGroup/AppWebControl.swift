//
//  AppWebControl.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/23.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import UIKit

final class AppWebControl: CommonWebController {
    
    convenience init(name: String) {
        self.init(.app(name))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = group.title
        start()
    }
}
