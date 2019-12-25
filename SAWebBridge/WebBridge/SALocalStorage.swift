//
//  SALocalStorage.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/18.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation

public protocol SALocalStorageProtocol {
    func identifier() -> String
    func set(_ item: String?, for key: String)
    func get(itemFor key: String) -> String?
    func remove(itemFor key: String)
    func clear()
}


public class SALocalStorage {
    /// Actions for localStorage.
    public enum SALocalStorageAction: String {
        case setItem
        case getItem
        case removeItem
        case clear
    }
    
    public class LocalStorageIdentifier {
        var id: String = "default.localStorage"
    }
    
    static let `default` = SALocalStorage()
    
    private var flag = LocalStorageIdentifier()
    
    public func id(_ id: String) -> LocalStorageIdentifier {
        flag.id = id
        return flag
    }
}

extension SALocalStorage.LocalStorageIdentifier {
    private func cacheKey(_ key: String) -> String {
        return identifier() + key
    }
}

extension SALocalStorage.LocalStorageIdentifier: SALocalStorageProtocol {
    public func identifier() -> String {
        return id
    }
    
    public func set(_ item: String?, for key: String) {
        UserDefaults.standard.set(item, forKey: cacheKey(key))
        UserDefaults.standard.synchronize()
    }
    
    public func get(itemFor key: String) -> String? {
        return UserDefaults.standard.string(forKey: cacheKey(key))
    }
    
    public func remove(itemFor key: String) {
        UserDefaults.standard.removeObject(forKey: cacheKey(key))
        UserDefaults.standard.synchronize()
    }
    
    public func clear() {
        UserDefaults.standard.dictionaryRepresentation().keys.forEach({ key in
            if key.hasPrefix(identifier()) {
                UserDefaults.standard.removeObject(forKey: key)
            }
        })
        UserDefaults.standard.synchronize()
    }
}
