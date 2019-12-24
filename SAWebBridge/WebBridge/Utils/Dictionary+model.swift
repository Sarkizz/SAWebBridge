//
//  Dictionary+model.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/19.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation

extension Dictionary: SANamespaceWrappable {}
extension SANamespaceProtocol where WrappedType == [String: Any] {
    public func mapModel<T>(_ type: T.Type, map: [String: String]? = nil) throws -> T where T: Decodable {
        var src = self.value
        if let map = map {
            src = Dictionary(uniqueKeysWithValues: self.value.map({ k, v in
                return (map[k] ?? k, v)
            }))
        }
        let data = try JSONSerialization.data(withJSONObject: src, options: [])
        return try data.sa.mapModel(type)
    }
}

extension Data: SANamespaceWrappable {}
extension SANamespaceProtocol where WrappedType == Data {
    public func mapModel<T>(_ type: T.Type,
                            mapping: ((_ data: Data) -> Data)? = nil,
                            decoder: JSONDecoder = JSONDecoder()) throws -> T where T: Decodable {
        return try decoder.decode(type, from: mapping?(self.value) ?? self.value)
    }
}
