//
//  URL+utils.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/23.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation

extension URL {
    func content() throws -> Data {
        let handler = try FileHandle(forReadingFrom: self)
        return handler.readDataToEndOfFile()
    }
}
