//
//  ProgressEvent.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/24.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation

class ProgressEvent {
    class func handle(data: Any? = nil, completion: @escaping (_ result: EventResult<Any?, CustomEventHandler.EventError>) -> Void) {
        countdown(sec: 10, progress: { (p) in
            completion(.progress(p))
        }) {
            completion(.success(nil))
        }
    }
}

extension ProgressEvent {
    class func after(queue: DispatchQueue = .global(), sec: Int, completion: @escaping () -> Void) {
        queue.asyncAfter(deadline: .now() + .seconds(sec), execute: completion)
    }
    
    class func countdown(queue: DispatchQueue = .global(),
                         sec: Int,
                         progress: ((_ progress: Double) -> Void)?,
                         completion: @escaping () -> Void) {
        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer.schedule(deadline: .now(), repeating: 1)
        var downSec = 0
        timer.setEventHandler(handler: {
            progress?(Double(downSec)/Double(sec))
            if downSec >= sec {
                completion()
                timer.suspend()
                timer.cancel()
            }
            downSec += 1
        })
        timer.resume()
    }
}
