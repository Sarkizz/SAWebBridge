//
//  ImagePicker.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/19.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import UIKit

class ImagePicker: NSObject {
    
    struct ImagePickerError: Error {
        enum ErrorCode {
            case system
            case notFound
            case cancel
        }
        var code: ErrorCode
        var msg: String?
    }
    
    struct ImageResult {
        enum ImageType: String {
            case png
            case jpg
            case jpeg
            case gif
        }
        
        var image: UIImage
        var type: ImageType
        var url: URL?
    }
    
    enum ShowType {
        case all(UIImagePickerController.CameraDevice = .rear)
        case camera(device: UIImagePickerController.CameraDevice = .rear)
        case photoLibrary
        case savedPhotosAlbum
    }
    
    struct Config {
        var cameraTitle: String = "拍照"
        var libraryTitle: String = "我的相册"
        var albumTitle: String = "照片"
        var cancelTitle: String = "取消"
    }
    
    typealias ImagePickerCompletion = (_ result: Result<ImageResult, ImagePickerError>) -> Void
    
    static let shared = ImagePicker()
    var config = Config()
    
    private var completion: ImagePickerCompletion?
    private var editable = false
    
    func show(_ type: ShowType = .all(),
              in viewController: UIViewController? = nil,
              title: String? = nil,
              editable: Bool = false,
              completion: @escaping ImagePickerCompletion) {
        self.editable = editable
        self.completion = completion
        switch type {
        case .all(let device):
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: config.cameraTitle, style: .default, handler: { _ in
                self.showImagePicker(.camera, device: device, editable: editable, in: viewController, title: self.config.cameraTitle)
            }))
            alert.addAction(UIAlertAction(title: config.libraryTitle, style: .default, handler: { _ in
                self.showImagePicker(.photoLibrary, editable: editable, in: viewController, title: self.config.libraryTitle)
            }))
            alert.addAction(UIAlertAction(title: config.albumTitle, style: .default, handler: { _ in
                self.showImagePicker(.savedPhotosAlbum, editable: editable, in: viewController, title: self.config.albumTitle)
            }))
            alert.addAction(UIAlertAction(title: config.cancelTitle, style: .cancel, handler: { _ in
                completion(.failure(.init(code: .cancel)))
            }))
            let root = viewController ?? UIApplication.shared.keyWindow?.rootViewController
            root?.present(alert, animated: true, completion: nil)
        case .camera(let device):
            showImagePicker(.camera, device: device, editable: editable, in: viewController, title: self.config.cameraTitle)
        case .photoLibrary:
            showImagePicker(.photoLibrary, editable: editable, in: viewController, title: self.config.libraryTitle)
        case .savedPhotosAlbum:
            showImagePicker(.savedPhotosAlbum, editable: editable, in: viewController, title: self.config.albumTitle)
        }
    }
}

extension ImagePicker {
    private func showImagePicker(_ type: UIImagePickerController.SourceType,
                                 device: UIImagePickerController.CameraDevice? = nil,
                                 editable: Bool,
                                 in viewController: UIViewController? = nil,
                                 title: String? = nil) {
        let vc = UIImagePickerController()
        vc.sourceType = type
        vc.delegate = self
        vc.title = title
        vc.allowsEditing = editable
        if type == .camera, let device = device {
            vc.cameraDevice = device
        }
        let root = viewController ?? UIApplication.shared.keyWindow?.rootViewController
        root?.present(vc, animated: true, completion: nil)
    }
}

extension ImagePicker: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var image: UIImage? {
            let img = editable ? info[.editedImage] as? UIImage : info[.originalImage] as? UIImage
            return img
        }
        
        var result: ImageResult? {
            if picker.sourceType == .camera, let image = image {
                return .init(image: image, type: .png)
            } else {
                guard let img = image,
                    let url = info[.imageURL] as? URL,
                    let type = ImageResult.ImageType(rawValue: url.pathExtension.lowercased()) else {
                        return nil
                }
                return .init(image: img, type: type, url: url)
            }
        }
        
        if let result = result {
            completion?(.success(result))
        } else {
            completion?(.failure(.init(code: .notFound)))
        }
        picker.dismiss(animated: true)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        completion?(.failure(.init(code: .cancel)))
        picker.dismiss(animated: true)
    }
}
