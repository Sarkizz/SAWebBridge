//
//  CustomNotificationManager.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/18.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import SAWebBridge

enum WebNotifyEvents: String {
    case enterBackground = "event.app.background"
    case enterForeground = "event.app.foreground"
}

class CustomNotificationManager {
    static let shared = CustomNotificationManager()
    
    let manager = SAWebNotificationManager<CustomWebView>()
    
    func setup() {
        manager.main = .init(with: MainWebController.default.webView)
    }
}

extension CustomNotificationManager {
    func notify(_ event: WebNotifyEvents, data: Any? = nil, callback: SAWebNotificationManager<CustomWebView>.Callback? = nil) {
        manager.notify(event: event.rawValue, data: data, callback: callback)
    }
}
