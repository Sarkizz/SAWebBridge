//
//  SAWebNotificationManager.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/18.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import WebKit

public class SAWeakObj<T: SAWebViewProtocol>: NSObject {
    public weak var obj: T?
    
    public var sessionId: Int = 0
    public var callbacks = [Int: SAWebNotificationManager<T>.Callback]()
    
    public required init(with obj: T) {
        self.obj = obj
    }
    
    static func == (lhs: SAWeakObj<T>, rhs: SAWeakObj<T>) -> Bool {
        return lhs.obj == rhs.obj
    }
}

public class SAWebNotificationManager<T: SAWebViewProtocol> {
    
    public typealias SANotificationEvent = String
    public typealias SANotificationAPI = String
    
    public var main: SAWeakObj<T>?
    
    private var notifications = [String: Set<SAWeakObj<T>>]()
    
    public init() {}
}

extension SAWebNotificationManager {
    public func add(notify: T, for key: String) {
        var set = notifications[key] ?? Set<SAWeakObj<T>>()
        set.insert(SAWeakObj(with: notify))
        notifications[key] = set
    }
    
    public func remove(notify: T, for key: String) {
        if var set = notifications[key] {
            set.remove(SAWeakObj(with: notify))
            if set.count > 0 {
                notifications[key] = set
            } else {
                notifications.removeValue(forKey: key)
            }
        }
    }
}

extension SAWebNotificationManager {
    
    public struct Callback {
        
        public struct RejectError: Codable {
            public var code: String
            public var msg: String
        }
        
        public typealias Resolve = (_ data: Any?) -> Void
        public typealias Reject = (_ error: RejectError?) -> Void
        
        public var resolve: Resolve?
        public var reject: Reject?
        
        public init(resolve: Resolve? = nil, reject: Reject? = nil) {
            self.resolve = resolve
            self.reject = reject
        }
    }
    
    public func notify(event: SANotificationEvent, data: Any? = nil, callback: Callback? = nil) {
        if let set = notifications[event], let main = main {
            set.forEach {
                if let obj = $0.obj {
                    let id = main.sessionId + 1
                    if let callback = callback {
                        main.callbacks[id] = callback
                    }
                    obj.asyncCallback(.rs(type: .exec, id: id, key: event, data: data))
                    main.sessionId = id
                }
            }
        }
    }
    
    public func call(api: SANotificationAPI, data: Any? = nil, context: [String: Any]? = nil, callback: Callback? = nil) {
        if let main = main, let web = main.obj {
            let id = main.sessionId + 1
            if let callback = callback {
                main.callbacks[id] = callback
            }
            web.asyncCallback(.rs(type: .exec, id: id, key: api, data: data, context: context))
            main.sessionId = id
        }
    }
    
    public func reslove(_ id: Int, data: Any? = nil) {
        main?.callbacks[id]?.resolve?(data)
    }
    
    public func reject(_ id: Int, data: Any? = nil) {
        var error: Callback.RejectError? {
            if let data = data as? [String: Any], let rs = try? data.sa.mapModel(Callback.RejectError.self) {
                return rs
            }
            return nil
        }
        main?.callbacks[id]?.reject?(error)
    }
}
