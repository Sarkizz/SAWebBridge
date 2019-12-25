//
//  UIAlertController+util.swift
//  MRFramework
//
//  Created by Sarkizz on 2019/11/8.
//  Copyright © 2019 sarkizz. All rights reserved.
//

import Foundation
import UIKit

extension UIAlertController: SANamespaceWrappable {}
extension SANamespaceProtocol where WrappedType == UIAlertController {
    public static func panel(title: String? = nil,
                            message: String?,
                            buttonTitle: String = "确定",
                            completion: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: buttonTitle, style: .default, handler: completion))
        return alert
    }
    
    public static func confirmPanel(title: String? = nil,
                                   message: String?,
                                   confirmTitle: String = "是",
                                   cancelTitle: String = "否",
                                   completion: ((UIAlertAction, Bool) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: confirmTitle, style: .default, handler: { action in
            completion?(action, true)
        }))
        alert.addAction(.init(title: cancelTitle, style: .cancel, handler: { action in
            completion?(action, false)
        }))
        return alert
    }
    
    public static func prompt(title: String? = nil,
                             message: String?,
                             textFieldConfig: ((UITextField) -> Void)? = nil,
                             confirmTitle: String = "确定",
                             cancelTitle: String = "取消",
                             completion: ((UIAlertAction, String?) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField(configurationHandler: textFieldConfig)
        alert.addAction(.init(title: confirmTitle, style: .default, handler: { action in
            completion?(action, alert.textFields?[0].text)
        }))
        alert.addAction(.init(title: cancelTitle, style: .cancel))
        return alert
    }
    
    public static func actionSheet(title: String? = nil,
                                  message: String?,
                                  cancelTitle: String = "取消",
                                  sheets: [String],
                                  completion: ((UIAlertAction, Int) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        sheets.enumerated().forEach({ idx, title in
            alert.addAction(.init(title: title, style: .default, handler: { (action) in
                completion?(action, idx)
            }))
        })
        alert.addAction(.init(title: cancelTitle, style: .cancel))
        return alert
    }
}
