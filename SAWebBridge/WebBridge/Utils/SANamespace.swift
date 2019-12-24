//
//  SANamespace.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/24.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation

public protocol SANamespaceProtocol {
    associatedtype WrappedType
    var value: WrappedType { get }
    init(_ v: WrappedType)
}

public struct SANamespaceWarpper<T>: SANamespaceProtocol {
    public let value: T
    public init(_ v: T) {
        value = v
    }
}

public protocol SANamespaceWrappable {}
public extension SANamespaceWrappable {
    var sa: SANamespaceWarpper<Self> { return SANamespaceWarpper(self) }
    static var sa: SANamespaceWarpper<Self>.Type { return SANamespaceWarpper.self }
}

