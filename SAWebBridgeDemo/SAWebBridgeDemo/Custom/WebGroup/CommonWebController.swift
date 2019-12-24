//
//  CommonWebController.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/23.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import SnapKit

public enum WebGroup: Equatable {
    case main
    case app(_ name: String)
    case link(_ url: URL)
    
    public static func ==(lhs: WebGroup, rhs: WebGroup) -> Bool {
        switch (lhs, rhs) {
        case (.main, .main):
            return true
        case let (.link(lu), .link(ru)):
            return lu == ru
        case let (.app(ln), .app(rn)):
            return ln == rn
        default:
            return false
        }
    }
    
    var loadType: LoadType {
        switch self {
        case .main:
            return .local(Bundle.main.resourceURL!.appendingPathComponent("DemoHTML/indexMain.html"), Bundle.main.resourceURL!)
        case .app:
            return .local(Bundle.main.resourceURL!.appendingPathComponent("DemoHTML/indexApp.html"), Bundle.main.resourceURL!)
        case .link(let url):
            let request = NSMutableURLRequest(url: url)
            request.timeoutInterval = CommonWebController.timeout
            return .request(request)
        }
    }
    
    var title: String? {
        switch self {
        case .app(let name):
            return name
        default:
            return nil
        }
    }
}

open class CommonWebController: UIViewController {
    
    static let timeout: TimeInterval = 20
    
    public enum Status: Equatable {
        public static func == (lhs: CommonWebController.Status, rhs: CommonWebController.Status) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none): return true
            case (.loading, .loading): return true
            case (.success, .success): return true
            case (.fail, .fail): return true
            default:
                return false
            }
        }
        
        case none
        case loading
        case success
        case fail(_ error: Error)
    }
    
    public var status: Status = .none {
        didSet {
            statusDidChange()
        }
    }
    
    public let group: WebGroup
    let webView: CustomWebView
    
    private let uiDelegate = SAWebViewUIDelegateHandler<CustomWebView>()
    private let navDelegate = SAWebViewNavigationDelegateHandler<CustomWebView>()
    
    private let loadingIndicator = UIActivityIndicatorView(style: .gray)
    
    required public init(_ group: WebGroup) {
        self.group = group
        var shouldHook: Bool {
            switch group {
            case .main, .app:
                return true
            default:
                return false
            }
        }
        webView = .webView(.init(shouldHookLocalStorage: shouldHook))
        super.init(nibName: nil, bundle: nil)
        webView.delegate = self
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
    }
}

extension CommonWebController {
    public func start() {
        webView.loadWeb()
        // Show progress view
    }
    
    public func reload() {
        webView.reload()
    }
    
    public func addReloadButton() {
        let item = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadWeb))
        self.navigationItem.rightBarButtonItem = item
    }
}

extension CommonWebController {
    private func setupWebView() {
        webView.loadType = group.loadType
        navDelegate.didFinishLoading = {[weak self] webView, _ in
            switch self?.group {
            case .link:
                webView.evaluateJavaScript("document.title", completionHandler: { text, _ in
                    self?.title = text as? String
                })
            default:
                break
            }
            self?.status = .success
        }
        
        navDelegate.didFailLoading = { [weak self] _, _, error in
            self?.status = .fail(error)
        }
        
        webView.uiDelegate = uiDelegate
        webView.navigationDelegate = navDelegate
        
        view.addSubview(webView)
        webView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 40, height: 40))
            make.center.equalToSuperview()
        }
    }
    
    private func statusDidChange() {
        switch status {
        case .loading:
            loadingIndicator.startAnimating()
        case .fail(let error):
            loadingIndicator.stopAnimating()
            if webView.isLoading {
                webView.stopLoading()
            }
            SADLog("Load web failed: \(error)")
        default:
            loadingIndicator.stopAnimating()
            break
        }
    }
    
    @objc private func reloadWeb() {
        reload()
    }
    
    private func checkTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(CommonWebController.timeout))) {
            if self.status == .loading {
                self.status = .fail(NSError(domain: "com.webview.load.timeout", code: -88))
            }
        }
    }
}

extension CommonWebController: CustomWebViewDelegate {
    func webView(_ webView: CustomWebView, handleJSMessage info: SAWebJSManager.SAWebJSScriptInfo, result: @escaping (SAJSHandleResult) -> Void) {
        switch info.action {
        case .event(let type):
            switch type {
            case .sync(let name):
                if let event = CustomSyncEvents(rawValue: name) {
                    let rs = CustomEventHandler.sync.handle(event: event, group: group, data: info.params, vc: self)
                    switch rs {
                    case .success(let data):
                        result(.sync(data: data))
                    case .failure(let error):
                        result(.sync(code: error.returnCode, data: error.msg))
                    case .progress(let p):
                        result(.progress(p))
                    }
                } else {
                    result(.sync(code: SAReturnCode.invaildAction.rawValue, data: nil))
                }
            case .async(let name):
                if let event = CustomAsyncEvents(rawValue: name) {
                    result(.promise)
                    CustomEventHandler.async.handle(event: event, group: group, data: info.params, vc: self, completion: { rs in
                        switch rs {
                        case .success(let rs):
                            result(.promiseResult(data: ["img": rs]))
                        case .failure(let err):
                            result(.promiseResult(code: err.returnCode))
                        case .progress(let p):
                            result(.progress(p))
                        }
                    })
                } else {
                    result(.sync(code: SAReturnCode.invaildAction.rawValue, data: nil))
                }
            }
        case .notification(let type):
            webView.defaultNotificationHandle(type: type, info: info, result: result)
        case .localStorage(let action):
            webView.defaultLocalStorageHandle(action: action, data: info.params, result: result)
        default:
            result(.sync(code: SAReturnCode.unknow.rawValue))
        }
    }
    
    func webView(_ webView: CustomWebView, handlePolicy action: WKNavigationAction) -> Bool {
        if let url = action.request.url,
            let scheme = url.scheme,
            let policy = CustomPolicy(rawValue: scheme) {
            switch policy {
            case .tel, .sms, .mailto:
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
                return true
            }
        }
        return false
    }
    
    func webNotificationManager(_ webView: CustomWebView) -> SAWebNotificationManager<CustomWebView>? {
        return CustomNotificationManager.shared.manager
    }
}
