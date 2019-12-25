//
//  SAWebJSManager.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/17.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation

/// Keys for js message object which from web calling jssdk api.
public enum SAJSMessageKey: String {
    case sessionId
    case action
    case params
}

/// Callback object keys. When web call jssdk api,  native must callback immediately.
public enum SAJSCallbackKey: String {
    case code
    case sessionId
    case action
    case from
    case progress
    case data
}

/// Callback object types.
public enum SAJSCallbackType: String {
    case normal
    case promise
    case promise_result
    case progress
    case exec
}

/// JS event actions that parse from SAWebJSManager
public enum SAJSActionType {
    
    public enum NotificationType {
        case register(key: String)
        case unregister(key: String)
        case notify(key: String)
        case resolve
        case reject
    }
    
    public enum EventType {
        case sync(_ name: String)
        case async(_ name: String)
    }
    
    case none
    case event(_ type: EventType)
    case notification(_ type: NotificationType)
    case localStorage(action: SALocalStorage.SALocalStorageAction)
}

/// The default return codes. You can define your codes for yourself.
public enum SAReturnCode: String {
    
    case success = "SUCCESS"
    case failed = "FAILED"
    case cancel = "CANCEL"
    
    case missSessionId = "ERR_MISS_SESSIONID"
    case missAction = "ERR_MISS_ACTION"
    case invaildAction = "ERR_INVAILD_ACTION"
    case invaildParams = "ERR_INVAILD_PARAMS"
    case noData = "ERR_NO_DATA"
    case notFound = "ERR_NOT_FOUND"
    case unsupport = "ERR_NOT_SUPPORT"
    case timeout = "ERR_TIMEOUT"
    case permission = "ERR_NO_PERMISSION"
    case authorization = "ERR_AUTHORIZATION"
    case unknow = "ERR_UNKNOW"
}

public enum SAJSHandleResult {
    case sync(code: String = SAReturnCode.success.rawValue, data: Any? = nil)
    case promise
    case promiseResult(code: String = SAReturnCode.success.rawValue, data: Any? = nil)
    case progress(Double)// 0-1
    case notify(key: String, data: Any? = nil, context: [String: Any]? = nil)
}

open class SAWebJSManager {
    
    public static let `default` = SAWebJSManager(Setting())
    public var setting: Setting
    
    public struct Setting {
        let jssdkFlag = "jssdk."
        let syncEventFlag = "jssdk.sync."
        let asyncEventFlag = "jssdk.async."
        let registerFlag = "jssdk_register."
        let unregisterFlag = "jssdk_unregister."
        let resolveFlag = "jssdk_exec_resolve"
        let rejectFlag = "jssdk_exec_reject"
        let localStorageFlag = "jssdk.localStorage."
        var notifyAPIFlag = "api."
        var notifyEventFlag = "event."
    }
    
    public required init(_ setting: Setting) {
        self.setting = setting
    }
    
    public typealias CallbackResult = String
    
    public enum ResultType {
        case normal
        case missAction
        case invaildAction
        case missSessionId
        case unknow
    }
    
    public struct SAWebJSScriptInfo {
        
        public static let failedSessionId = -99998
        
        public static let missActionInfo = SAWebJSScriptInfo.init(type: .missAction, sessionId: failedSessionId, action: .none)
        public static let invaildActionInfo = SAWebJSScriptInfo.init(type: .invaildAction, sessionId: failedSessionId, action: .none)
        public static let missSessionId = SAWebJSScriptInfo.init(type: .missSessionId, sessionId: failedSessionId, action: .none)
        public static let unknowInfo = SAWebJSScriptInfo.init(type: .unknow, sessionId: failedSessionId, action: .none)
        
        public var type: ResultType
        public var sessionId: Int
        public var action: SAJSActionType
        public var params: Any?
        
        public static func normal(sessionId: Int, action: SAJSActionType, params: Any?) -> SAWebJSScriptInfo {
            return .init(type: .normal, sessionId: sessionId, action: action, params: params)
        }
    }
    
    open func shouldHandleScript(_ msg: String) -> Bool {
        return msg.hasPrefix("{\"type\": \"bridge\"")
    }
    
    open func parseScript(_ script: String) -> SAWebJSScriptInfo? {
        guard shouldHandleScript(script), let body = scriptToDic(script) else {
            return .unknowInfo
        }
        guard let id = body[.sessionId] as? Int else { return .missSessionId }
        guard let action = body[.action] as? String else { return .missActionInfo }
        let params = body[.params]
        if let key = registerKey(action) {
            return .normal(sessionId: id, action: .notification(.register(key: key)), params: params)
        } else if let key = unregisterKey(action) {
            return .normal(sessionId: id, action: .notification(.unregister(key: key)), params: params)
        } else if let event = syncEvent(action) {
            return .normal(sessionId: id, action: .event(.sync(event)), params: params)
        } else if let event = asyncEvent(action) {
            return .normal(sessionId: id, action: .event(.async(event)), params: params)
        } else if let key = notifyKey(action) {
            return .normal(sessionId: id, action: .notification(.notify(key: key)), params: params)
        } else if resolve(action) {
            return .normal(sessionId: id, action: .notification(.resolve), params: params)
        } else if reject(action) {
            return .normal(sessionId: id, action: .notification(.reject), params: params)
        } else if let type = localstorageType(action) {
            return .normal(sessionId: id, action: .localStorage(action: type), params: params)
        } else {
            return .invaildActionInfo
        }
    }
}

extension SAWebJSManager {
    
    private func scriptToDic(_ script: String) -> [SAJSMessageKey: Any]? {
        guard let data = script.data(using: .utf8) else {
            return nil
        }
        
        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            if let dict = obj as? [String: Any],
                let body = dict["body"] as? [String: Any] {
                
                let rs = Dictionary(uniqueKeysWithValues: body.map({k, v in
                    (SAJSMessageKey(rawValue: k), v)
                }).compactMap({ t in t.0 == nil ? nil : (t.0!, t.1) }))
                
                return rs
            }
        } catch {}
        return nil
    }
    
    private func registerKey(_ messageAction: String) -> String? {
        if messageAction.hasPrefix(setting.registerFlag) {
            return messageAction.replacingOccurrences(of: setting.registerFlag, with: "")
        }
        return nil
    }
    
    private func unregisterKey(_ messageAction: String) -> String? {
        if messageAction.hasPrefix(setting.unregisterFlag) {
            return messageAction.replacingOccurrences(of: setting.unregisterFlag, with: "")
        }
        return nil
    }
    
    private func syncEvent(_ messageAction: String) -> String? {
        if messageAction.hasPrefix(setting.syncEventFlag) {
            let action = messageAction.replacingOccurrences(of: setting.syncEventFlag, with: "")
            return action
        }
        return nil
    }
    
    private func asyncEvent(_ messageAction: String) -> String? {
        if messageAction.hasPrefix(setting.asyncEventFlag) {
            let action = messageAction.replacingOccurrences(of: setting.asyncEventFlag, with: "")
            return action
        }
        return nil
    }
    
    private func localstorageType(_ messageAction: String) -> SALocalStorage.SALocalStorageAction? {
        if messageAction.hasPrefix(setting.localStorageFlag) {
            let action = messageAction.replacingOccurrences(of: setting.localStorageFlag, with: "")
            return SALocalStorage.SALocalStorageAction(rawValue: action)
        }
        return nil
    }
    
    private func notifyKey(_ messageAction: String) -> String? {
        if messageAction.hasPrefix(setting.jssdkFlag+setting.notifyAPIFlag) ||
            messageAction.hasPrefix(setting.jssdkFlag+setting.notifyEventFlag) {
            return messageAction.replacingOccurrences(of: setting.jssdkFlag, with: "")
        }
        return nil
    }
    
    private func resolve(_ messageAction: String) -> Bool {
        return messageAction == setting.resolveFlag
    }
    
    private func reject(_ messageAction: String) -> Bool {
        return messageAction == setting.rejectFlag
    }
}

extension Dictionary {
    public var jsonString: String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: self, options: [])
            return String(data: data, encoding: .utf8)
        } catch let e {
            SADLog("Parse json error: \n\(e)")
        }
        return nil
    }
}

extension SAWebJSManager.CallbackResult {
    public static func rs(type: SAJSCallbackType,
                         code: String? = nil,
                         id: Int? = nil,
                         key: String? = nil,
                         data: Any? = nil,
                         context: [String: Any]? = nil) -> Self? {
        var rs: [String: Any] = ["type": type.rawValue]
        rs["code"] = code
        rs["sessionId"] = id
        rs["action"] = key
        if type == .progress {
            rs["progress"] = data
        } else {
            if let str = data as? String, str.contains("\"") && str.hasPrefix("{") {
                rs["data"] = str.replacingOccurrences(of: "\"", with: "\\\"")
            } else {
                rs["data"] = data
            }
        }
        if let context = context {
            rs["context"] = context
        }
        
        return rs.jsonString
    }
}
