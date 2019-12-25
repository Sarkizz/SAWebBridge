//
//  CustomWebView.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/18.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import WebKit
import SAWebBridge

enum CustomPolicy: String {
    case tel
    case sms
    case mailto
}

enum LoadType {
    case request(_ request: NSURLRequest)
    case local(_ fileURL: URL, _ accessURL: URL)
}

protocol CustomWebViewDelegate: class {
    func webView(_ webView: CustomWebView, handleJSMessage info: SAWebJSManager.SAWebJSScriptInfo, result: @escaping (SAJSHandleResult) -> Void)
    func webView(_ webView: CustomWebView, handlePolicy action: WKNavigationAction) -> Bool
    func webNotificationManager(_ webView: CustomWebView) -> SAWebNotificationManager<CustomWebView>?
}

final class CustomWebView: WKWebView, SAWebViewProtocol {
    
    public var loadType: LoadType?
    weak var delegate: CustomWebViewDelegate?
    
    func customJSMessage(with info: SAWebJSManager.SAWebJSScriptInfo, result: @escaping (SAJSHandleResult) -> Void) {
        delegate?.webView(self, handleJSMessage: info, result: result)
    }
    
    func handlePolicy(with action: WKNavigationAction) -> Bool {
        return delegate?.webView(self, handlePolicy: action) ?? false
    }
    
    func webNotificationManager() -> SAWebNotificationManager<CustomWebView>? {
        return delegate?.webNotificationManager(self)
    }
}

extension CustomWebView {
    func loadWeb() {
        if let type = loadType {
            switch type {
            case .request(let request):
                load(request as URLRequest)
            case .local(let indexURL, let access):
                loadFileURL(indexURL, allowingReadAccessTo: access)
            }
        }
    }
}
