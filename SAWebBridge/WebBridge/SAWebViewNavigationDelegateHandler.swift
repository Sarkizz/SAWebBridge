//
//  SAWebViewNavigationDelegateHandler.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/18.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import WebKit

open class SAWebViewNavigationDelegateHandler<T: SAWebViewProtocol>: NSObject, WKNavigationDelegate {

    public var didFinishLoading: ((_ webView: WKWebView, _ navigation: WKNavigation) -> Void)?
    public var didFailLoading: ((_ webView: WKWebView, _ navigation: WKNavigation, _ error: Error) -> Void)?

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let webView = webView as? T, webView.handlePolicy(with: navigationAction) {
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinishLoading?(webView, navigation)
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        didFailLoading?(webView, navigation, error)
    }
}
