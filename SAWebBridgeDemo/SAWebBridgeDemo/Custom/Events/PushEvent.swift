//
//  PushEvent.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/24.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import UIKit

class PushEvent {
    enum PushType {
        case app
        case link
        case back
        case close
    }
    
    class func handle(_ type: PushType, data: Any? = nil, vc: UIViewController) -> EventResult<Any?, CustomEventHandler.EventError> {
        switch type {
        case .app:
            if let data = data as? [String: Any], let name = data["name"] as? String {
                let app = AppWebControl(.app(name))
                vc.navigationController?.pushViewController(app, animated: true)
                return .success(nil)
            } else {
                return .failure(.init(code: .invaildParams))
            }
        case .link:
            if let data = data as? [String: Any], let urlStr = data["url"] as? String, let url = URL(string: urlStr) {
                let link = LinkWebControl(.link(url))
                vc.navigationController?.pushViewController(link, animated: true)
                return .success(nil)
            } else {
                return .failure(.init(code: .invaildParams))
            }
        case .back:
            if let vc = vc as? LinkWebControl {
                if vc.webView.canGoBack {
                    vc.webView.goBack()
                } else {
                    vc.navigationController?.popViewController(animated: true)
                }
            } else {
                vc.navigationController?.popViewController(animated: true)
            }
            return .success(nil)
        case .close:
            vc.navigationController?.popViewController(animated: true)
            return .success(nil)
        }
    }
}
