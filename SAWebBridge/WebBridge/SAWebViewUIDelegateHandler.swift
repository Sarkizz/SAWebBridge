//
//  SAWebViewUIDelegateHandler.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/17.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import WebKit

//public protocol SAWebViewUIProtocol: WKUIDelegate {
//    func scriptMessageManager() -> SAWebJSManager
//
//    func showPromptAlert(in viewController: UIViewController?,
//                         message: String,
//                         defaultText: String?,
//                         callback: @escaping (String?) -> Void)
//    func showPanelAlert(in viewController: UIViewController?,
//                        message: String,
//                        callback: @escaping () -> Void)
//    func showConfirmAlert(in viewController: UIViewController?,
//                          message: String,
//                          callback: @escaping (Bool) -> Void)
//}
//
//extension SAWebViewUIProtocol {
//    func scriptMessageManager() -> SAWebJSManager {
//        return .default
//    }
//
//    func showPromptAlert(in viewController: UIViewController?,
//                         message: String,
//                         defaultText: String?,
//                         callback: @escaping (String?) -> Void) {
//        if let viewController = viewController ?? UIApplication.shared.keyWindow?.rootViewController {
//            let alert = UIAlertController.prompt(message: message, textFieldConfig: { (textField) in
//                textField.font = UIFont.systemFont(ofSize: 16)
//                textField.text = defaultText
//            }) { (_, text) in
//                callback(text)
//            }
//            viewController.present(alert, animated: true)
//        }
//    }
//
//    func showPanelAlert(in viewController: UIViewController?,
//                        message: String,
//                        callback: @escaping () -> Void) {
//        if let viewController = viewController ?? UIApplication.shared.keyWindow?.rootViewController {
//            let alert = UIAlertController.panel(message: message) { _ in
//                callback()
//            }
//            viewController.present(alert, animated: true)
//        }
//    }
//
//    func showConfirmAlert(in viewController: UIViewController?,
//                          message: String,
//                          callback: @escaping (Bool) -> Void) {
//        if let viewController = viewController ?? UIApplication.shared.keyWindow?.rootViewController {
//            let alert = UIAlertController.confirmPanel(message: message, confirmTitle: "是", cancelTitle: "否") { (_, isConfirm) in
//                callback(isConfirm)
//            }
//            viewController.present(alert, animated: true)
//        }
//    }
//}
//
//extension SAWebViewUIProtocol {
//
//    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
//        if let info = scriptMessageManager().parseScript(prompt) {
//            webView.handleJSMessage(with: info, callback: completionHandler)
//        } else {
//            showPromptAlert(in: nil, message: prompt, defaultText: defaultText, callback: completionHandler)
//        }
//    }
//
//    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
//        showPanelAlert(in: nil, message: message, callback: completionHandler)
//    }
//
//    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
//        showConfirmAlert(in: nil, message: message, callback: completionHandler)
//    }
//}

open class SAWebViewUIDelegateHandler<T: SAWebViewProtocol>: NSObject, WKUIDelegate {
    
    public weak var jsmanager: SAWebJSManager? = .default

    open func customPrompt(in viewController: UIViewController? = nil,
                           message: String,
                           defaultText: String?,
                           callback: @escaping (String?) -> Void) {
        if let viewController = viewController ?? UIApplication.shared.keyWindow?.rootViewController {
            let alert = UIAlertController.sa.prompt(message: message, textFieldConfig: { (textField) in
                textField.font = UIFont.systemFont(ofSize: 16)
                textField.text = defaultText
            }) { (_, text) in
                callback(text)
            }
            viewController.present(alert, animated: true)
        }
    }

    open func customAlertPanel(in viewController: UIViewController? = nil,
                               message: String,
                               callback: @escaping () -> Void) {
        if let viewController = viewController ?? UIApplication.shared.keyWindow?.rootViewController {
            let alert = UIAlertController.sa.panel(message: message) { _ in
                callback()
            }
            viewController.present(alert, animated: true)
        }
    }

    open func customConfirmPanel(in viewController: UIViewController? = nil,
                                 message: String,
                                 callback: @escaping (Bool) -> Void) {
        if let viewController = viewController ?? UIApplication.shared.keyWindow?.rootViewController {
            let alert = UIAlertController.sa.confirmPanel(message: message, confirmTitle: "是", cancelTitle: "否") { (_, isConfirm) in
                callback(isConfirm)
            }
            viewController.present(alert, animated: true)
        }
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        if let info = jsmanager?.parseScript(prompt), let webView = webView as? T {
            webView.handleJSMessage(with: info, callback: completionHandler)
        } else {
            customPrompt(message: prompt, defaultText: defaultText, callback: completionHandler)
        }
    }

    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        customAlertPanel(message: message, callback: completionHandler)
    }

    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        customConfirmPanel(message: message, callback: completionHandler)
    }
}
