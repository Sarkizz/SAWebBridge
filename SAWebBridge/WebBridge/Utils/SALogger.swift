//
//  SALogger.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/20.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation

public func SADLog(_ msg: Any...) {
    #if DEBUG
    print(msg.map({
        return "\($0)"
        }).joined(separator: " "))
    #endif
}
