//
//  LinkWebControl.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/24.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation

final class LinkWebControl: CommonWebController {
    override func viewDidLoad() {
        super.viewDidLoad()
        addReloadButton()
        start()
    }
}
