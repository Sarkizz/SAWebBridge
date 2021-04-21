//
//  SAWebViewProtocol.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/17.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import WebKit

/// Types for remove message handler
public enum MessageHandlerRemoveType {
    case all
    case name(_ name: String)
}

/// Types for remove content rules
public enum RuleListRemoveType {
    case all
    case rule(_ rule: WKContentRuleList)
}

public class SAWebConfig {
    var shouldInjectJS: Bool
    var shouldHookLocalStorage: Bool
    var webConf: WKWebViewConfiguration
    
    public init(shouldInjectJS: Bool = true,
                shouldHookLocalStorage: Bool = false,
                webConf: WKWebViewConfiguration = .init()) {
        self.shouldInjectJS = shouldInjectJS
        self.shouldHookLocalStorage = shouldHookLocalStorage
        self.webConf = webConf
    }
}

// cache jsbridge's js string.After first reading file, it will cache the string frome file.
var _cacheJSBridge: String?
// cache jssdk's js string.After first reading file, it will cache the string frome file.
var _cacheJSSDK: String?

public protocol SAWebViewProtocol where Self: WKWebView {
    func customJSMessage(with info: SAWebJSManager.SAWebJSScriptInfo, result: @escaping (_ result: SAJSHandleResult) -> Void)
    func handlePolicy(with action: WKNavigationAction) -> Bool
    func webNotificationManager() -> SAWebNotificationManager<Self>?
    
    func localStorageIdentifier() -> String
    func didInjectBridge(_ params: Any)
    func didInjectSDK(_ result: Result<Any?, Error>)
}

public extension SAWebViewProtocol {
    
    func localStorageIdentifier() -> String {
        return "com.sa.default.localStorage"
    }
    
    func didInjectBridge(_ params: Any) {
        SADLog("JSBridge did inject with params: \(params)")
    }
    
    func didInjectSDK(_ result: Result<Any?, Error>) {
        switch result {
        case .success(let data):
            SADLog("Inject SDK success: \(data ?? "")")
        case .failure(let error):
            SADLog("Inject SDK error: \(error)")
        }
    }
}

// MARK: Initzation
extension SAWebViewProtocol {
    
    public static func webView(_ config: SAWebConfig = .init()) -> Self {
        if config.shouldInjectJS {
            if let js = jsbridge {
                config.webConf.addStart(script: js)
            }
            let wk = Self(frame: .zero, configuration: config.webConf)
            wk.add(handler: { (_, message) in
                let webView = message.webView as? Self
                webView?.didInjectBridge(message.body)
                if let js = jssdk(shouldHookLocalStorage: config.shouldHookLocalStorage) {
                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                        message.webView?.evaluateJavaScript(js, completionHandler: { rs, error in
                            var rs: Result<Any?, Error> {
                                if let error = error {
                                    return .failure(error)
                                } else {
                                    return .success(rs)
                                }
                            }
                            webView?.didInjectSDK(rs)
                        })
                    }
                }
            }, for: "initSDK")
            return wk
        } else {
            return Self(frame: .zero, configuration: config.webConf)
        }
    }
}

extension SAWebViewProtocol {
    public func asyncCallback(_ msg: SAWebJSManager.CallbackResult?) {
        DispatchQueue.main.async {
            let js = "window.__jssdk._onReceive('\(msg ?? "")')"
            self.evaluateJavaScript(js)
        }
    }
    
    public func handleJSMessage(with info: SAWebJSManager.SAWebJSScriptInfo, callback: @escaping (_ msg: String?) -> Void) {
        switch info.type {
        case .unknow:
             callback(.rs(type: .normal, code: SAReturnCode.unknow.rawValue))
        case .missSessionId:
            callback(.rs(type: .normal, code: SAReturnCode.missSessionId.rawValue))
        case .missAction:
            callback(.rs(type: .normal, code: SAReturnCode.missAction.rawValue))
        case .invaildAction:
            callback(.rs(type: .normal, code: SAReturnCode.invaildAction.rawValue))
        case .normal:
            self.customJSMessage(with: info) { [weak self] rs in
                switch rs {
                case .sync(let code, let data):
                    callback(.rs(type: .normal, code: code, id: info.sessionId, data: data))
                case .promise:
                    callback(.rs(type: .promise, id: info.sessionId))
                case .promiseResult(let code, let data):
                    self?.asyncCallback(.rs(type: .promise_result, code: code, id: info.sessionId, data: data))
                case .progress(let progress):
                    self?.asyncCallback(.rs(type: .progress, id: info.sessionId, data: Int(progress * 100)))
                case .notify(let key, let data, let context):
                    self?.asyncCallback(.rs(type: .exec, id: info.sessionId, key: key, data: data, context: context))
                }
            }
        }
    }
    
    public func defaultNotificationHandle(type: SAJSActionType.NotificationType, info: SAWebJSManager.SAWebJSScriptInfo,
                                          result: @escaping (SAJSHandleResult) -> Void) {
        guard let manager = webNotificationManager() else {
            result(.sync(code: SAReturnCode.unsupport.rawValue))
            return
        }
        switch type {
        case .register(let key):
            manager.add(notify: self, for: key)
            result(.sync())
        case .unregister(let key):
            manager.remove(notify: self, for: key)
            result(.sync())
        case .notify(let key):
            result(.promise)
            manager.call(api: key, data: info.params, context: ["flag": "sa"], callback: .init(resolve: { (data) in
                result(.promiseResult(code: SAReturnCode.success.rawValue, data: data))
            }, reject: { error in
                result(.promiseResult(code: SAReturnCode.failed.rawValue, data: error))
            }))
        case .resolve:
            manager.reslove(info.sessionId, data: info.params)
            result(.sync())
        case .reject:
            manager.reject(info.sessionId, data: info.params)
            result(.sync())
        }
    }
    
    public func defaultLocalStorageHandle(action: SALocalStorage.SALocalStorageAction, data: Any?,
                                          result: @escaping (SAJSHandleResult) -> Void) {
        guard let data = data as? [String: Any], let key = data["key"] as? String else {
            if action == .clear {
                SALocalStorage.default.id(localStorageIdentifier()).clear()
                result(.sync())
            } else {
                result(.sync(code: SAReturnCode.failed.rawValue))
            }
            return
        }
        switch action {
        case .getItem:
            result(.sync(data: SALocalStorage.default.id(localStorageIdentifier()).get(itemFor: key)))
        case .setItem:
            SALocalStorage.default.id(localStorageIdentifier()).set(data["value"] as? String, for: key)
            result(.sync())
        case .removeItem:
            SALocalStorage.default.id(localStorageIdentifier()).remove(itemFor: key)
            result(.sync())
        default:
            // Will not go into this case
            result(.sync(code: SAReturnCode.failed.rawValue))
            break
        }
    }
}

// MARK: Syntax for message handlers and content rules
extension SAWebViewProtocol {
    
    private var messageHandlers: NSMutableSet {
        guard let set = objc_getAssociatedObject(self, "com.sa.messageHandler.cache.key") as? NSMutableSet else {
            let set = NSMutableSet()
            objc_setAssociatedObject(self, "com.sa.messageHandler.cache.key", set, .OBJC_ASSOCIATION_RETAIN)
            return set
        }
        return set
    }
    
    public func add(handler: @escaping SAWebJSHandler.SAWebJSMessageHandler, for name: String) {
        configuration.userContentController.add(SAWebJSHandler(handler), name: name)
        messageHandlers.adding(name)
    }
    
    public func add(handler: @escaping SAWebJSStringHandler.SAWebJSStringMessageHandler, for name: String) {
        configuration.userContentController.add(SAWebJSStringHandler(handler), name: name)
        messageHandlers.adding(name)
    }
    
    public func removeJSHandler(with type: MessageHandlerRemoveType = .all) {
        switch type {
        case .all:
            messageHandlers.forEach({
                if let name = $0 as? String {
                    configuration.userContentController.removeScriptMessageHandler(forName: name)
                }
            })
            messageHandlers.removeAllObjects()
        case .name(let name):
            configuration.userContentController.removeScriptMessageHandler(forName: name)
            messageHandlers.remove(name)
        }
    }
    
    public func addRuleList(_ ruleList: WKContentRuleList) {
        configuration.userContentController.add(ruleList)
    }
    
    public func removeRuleList(with type: RuleListRemoveType = .all) {
        switch type {
        case .all:
            configuration.userContentController.removeAllContentRuleLists()
        case .rule(let ruleList):
            configuration.userContentController.remove(ruleList)
        }
    }
}

// MARK: JS injection
extension SAWebViewProtocol {
    
    private static var jsbridge: String? {
        guard let jsbridge = _cacheJSBridge else {
            let js = injectScript(with: "jsbridge.js")
            _cacheJSBridge = js
            return js
        }
        return jsbridge
    }
    
    public static func jssdk(shouldHookLocalStorage: Bool = false) -> String? {
        var script: String? {
            if let js = _cacheJSSDK {
                return js
            } else {
                let js = injectScript(with: "jssdk.js")
                _cacheJSSDK = js
                return js
            }
        }
        
        if var script = script {
            script += "\r\nwindow.__jssdk = new Jssdk()"
            if shouldHookLocalStorage {
                script += "\r\nwindow.__jssdk._hookLocalStorage()"
            }
            script += "\r\nwindow.$jssdk = window.__jssdk.exec.bind(window.__jssdk)"
            script += "\r\nwindow.$register = window.__jssdk.register.bind(window.__jssdk)"
            script += "\r\nwindow.$unregister = window.__jssdk.unregister.bind(window.__jssdk)"
            script += "\r\nwindow.$resolve = window.__jssdk.resolve.bind(window.__jssdk)"
            script += "\r\nwindow.$reject = window.__jssdk.reject.bind(window.__jssdk)"
            script += "\r\nwindow.jsbridge.onInited && window.jsbridge.onInited(true)"
            
            return script
        }
        return nil
    }
    
    private static func injectScript(with fileName: String) -> String? {
        let bundle = Bundle(for: SAWebJSManager.self)
        if let url = bundle.resourceURL?.appendingPathComponent(fileName),
            let data = FileHandle.init(forReadingAtPath: url.path)?.readDataToEndOfFile(),
            let script = String(data: data, encoding: .utf8) {
            return script
        }
        return nil
    }
}

// MARK: WKWebViewConfiguration
extension WKWebViewConfiguration {
    public func add(script: WKUserScript) {
        userContentController.addUserScript(script)
    }
    
    public func addStart(script: String, for mainFrameOnly: Bool = false) {
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: mainFrameOnly)
        add(script: userScript)
    }
    
    public func addEnd(script: String, for mainFrameOnly: Bool = false) {
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: mainFrameOnly)
        add(script: userScript)
    }
    
    public func removeAllUserScripts() {
        userContentController.removeAllUserScripts()
    }
}
