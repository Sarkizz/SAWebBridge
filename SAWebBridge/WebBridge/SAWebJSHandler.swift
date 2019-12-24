//
//  SAWebJSHandler.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/17.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import WebKit

public class SAWebJSHandler: NSObject, WKScriptMessageHandler {
    
    public typealias SAWebJSMessageHandler = (_ userContentController: WKUserContentController, _ message: WKScriptMessage) -> Void
    
    private var handler: SAWebJSMessageHandler
    
    public init(_ handler: @escaping SAWebJSMessageHandler) {
        self.handler = handler
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handler(userContentController, message)
    }
}

public class SAWebJSStringHandler: NSObject, WKScriptMessageHandler {
    public typealias SAWebJSStringMessageHandler = (_ script: String) -> Void
    
    private var handler: SAWebJSStringMessageHandler
    
    public init(_ handler: @escaping SAWebJSStringMessageHandler) {
        self.handler = handler
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let script = message.body as? String {
            handler(script)
        }
    }
}
