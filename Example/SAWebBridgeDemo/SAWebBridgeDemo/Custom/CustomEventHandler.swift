//
//  CustomEventHandler.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/18.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import UIKit

enum CustomSyncEvents: String {
    case sdk_ready = "sdk.ready"
    case device_type = "device.type"
    case main_only = "main.only"
    case push_app = "push.app"
    case push_link = "push.link"
    case back
    case close
}

enum CustomAsyncEvents: String {
    case photo = "photo"
    case progress = "progress"
}

enum EventResult<Success, Failure> where Failure: Error {
    case success(Success)
    case failure(Failure)
    case progress(Double)
    
    func get() throws -> Success {
        switch self {
        case .success(let s):
            return s
        default:
            throw NSError(domain: "com.result.error", code: -99, userInfo: [NSLocalizedDescriptionKey: "not success"])
        }
    }
}

class CustomEventHandler {
    
    struct EventError: Error {
        enum EventErrorCode {
            case unknow
            case failed
            case cancel
            case invaildParams
        }
        
        var code: EventErrorCode
        var msg: String?
        
        var returnCode: String {
            switch code {
            case .invaildParams:
                return SAReturnCode.invaildParams.rawValue
            case .cancel:
                return SAReturnCode.cancel.rawValue
            case .failed:
                return SAReturnCode.failed.rawValue
            case .unknow:
                return SAReturnCode.unknow.rawValue
            }
        }
    }
    
    class SyncOperator {}
    class AsyncOperator {}
    
    static let sync = SyncOperator()
    static let async = AsyncOperator()
}

extension CustomEventHandler.SyncOperator {
    func handle(event: CustomSyncEvents,
                group: WebGroup,
                data: Any? = nil,
                vc: UIViewController) -> EventResult<Any?, CustomEventHandler.EventError> {
        switch event {
        case .sdk_ready:
            SADLog("jssdk did ready")
            return .success(nil)
        case .device_type:
            return .success("iOS")
        case .main_only:
            switch group {
            case .main:
                return .success("Main")
            default:
                return .failure(.init(code: .failed, msg: "main only"))
            }
        case .push_app:
            return PushEvent.handle(.app, data: data, vc: vc)
        case .push_link:
            return PushEvent.handle(.link, data: data, vc: vc)
        case .back:
            return PushEvent.handle(.back, vc: vc)
        case .close:
            return PushEvent.handle(.close, vc: vc)
        }
    }
}

extension CustomEventHandler.AsyncOperator {
    func handle(event: CustomAsyncEvents,
                group: WebGroup,
                data: Any? = nil,
                vc: UIViewController,
                completion: @escaping (_ result: EventResult<Any?, CustomEventHandler.EventError>) -> Void) {
        switch event {
        case .photo:
            PhotoEvent.handle(with: data) { result in
                switch result {
                case .success(let rs):
                    completion(.success(rs))
                case .failure(let error):
                    completion(.failure(error))
                default:
                    break
                }
            }
        case .progress:
            ProgressEvent.handle(data: data, completion: completion)
        }
    }
}
