//
//  PhotoEvent.swift
//  SAWebBridgeDemo
//
//  Created by Sarkizz on 2019/12/19.
//  Copyright © 2019 Sarkizz. All rights reserved.
//

import Foundation
import UIKit
import SAWebBridge

class PhotoEvent {
    
    struct PhotoInfo: Codable {
        
        static let `default` = PhotoInfo()
        
        enum DataType: String, Codable {
            case file
            case base64
        }
        
        var type: DataType = .base64
        var quality: CGFloat?
        var size: CGSize?
        var name: String?
    }
    
    private static let imageCacheURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private static let fileQueue = DispatchQueue(label: "com.sa.file.queue")
    
    public class func handle(with data: Any? = nil, completion: ((_ result: EventResult<String, CustomEventHandler.EventError>) -> Void)?) {
        var info: PhotoInfo {
            if let data = data as? [String: Any], let info = try? data.sa.mapModel(PhotoInfo.self) {
                return info
            }
            return .default
        }
        getPhoto({ result in
            switch result {
            case .success(var rs):
                fileQueue.async {
                    var image = rs.image
                    if let size = info.size, let img = image.thumb(with: size) {
                        image = img
                    }
                    rs.image = image
                    let fileExtension = info.quality == nil ? "png" : "jpg"
                    
                    switch info.type {
                    case .base64:
                        if let dataurl = dataURL(rs, quality: info.quality) {
                            DispatchQueue.main.async {
                                completion?(.success(dataurl))
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion?(.failure(.init(code: .failed)))
                            }
                        }
                    case .file:
                        let name = info.name ?? "com.sa.image_\(Date().timeIntervalSince1970).\(fileExtension)"
                        cache(image: image, name: name, quality: info.quality) { (result) in
                            switch result {
                            case .success(let path):
                                DispatchQueue.main.async {
                                    completion?(.success(path))
                                }
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    completion?(.failure(error))
                                }
                            }
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion?(.failure(error))
                }
            }
        })
    }
}

extension PhotoEvent {
    
    private class func getPhoto(_ completion: @escaping (_ result: Result<ImagePicker.ImageResult, CustomEventHandler.EventError>) -> Void) {
        ImagePicker.shared.show { result in
            switch result {
            case .success(let rs):
                completion(.success(rs))
            case .failure(let error):
                if error.code == .cancel {
                    completion(.failure(.init(code: .cancel)))
                } else {
                    completion(.failure(.init(code: .failed)))
                }
            }
        }
    }
    
    private class func cache(image: UIImage, name: String, quality: CGFloat? = nil,
                             completion: @escaping (_ result: Result<String, CustomEventHandler.EventError>) -> Void ) {
        image.cache(with: imageCacheURL.appendingPathComponent(name), quality: quality) { rs in
            switch rs {
            case .success(let url):
                completion(.success(url.path))
            case .failure(let error):
                completion(.failure(.init(code: .failed, msg: error.localizedDescription)))
            }
        }
    }
    
    private class func dataURL(_ source: ImagePicker.ImageResult, quality: CGFloat? = nil) -> String? {
        switch source.type {
        case .png:
            return source.image.dataURL(type: .png)
        case .jpg, .jpeg:
            return source.image.dataURL(type: .jpg(quality))
        case .gif:
            return gifDataURL(source)
        }
    }
    
    private class func gifDataURL(_ source: ImagePicker.ImageResult) -> String? {
        guard let url = source.url else { return nil }
        do {
            let data = try url.content()
            let base64 = data.base64EncodedString()
            return "data:image/gif;base64,\(base64)"
        } catch let e {
            SADLog(e)
            return nil
        }
    }
}

extension UIImage {
    
    enum DataURLType {
        case png
        case jpg(_ quality: CGFloat? = nil)
        case gif
    }
    
    func cache(with url: URL, quality: CGFloat? = nil, result: ((_ result: Result<URL, Error>) -> Void)?) {
        if let error = write(to: url, quality: quality) {
            result?(.failure(error))
        } else {
            result?(.success(url))
        }
    }
    
    func thumb(with size: CGSize) -> UIImage? {
        let size = sizeForFit(CGSize(width: size.width * scale, height: size.width * scale))
        UIGraphicsBeginImageContextWithOptions(size, true, scale)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func dataURL(type: DataURLType = .png) -> String? {
        switch type {
        case .png:
            return pngDataURL()
        case .jpg(let quality):
            return jpegDataURL(quality: quality ?? 1)
        case .gif:
            return nil
        }
    }
    
    func jpegDataURL(quality: CGFloat = 1) -> String? {
        if let base64 = jpegData(compressionQuality: quality)?.base64EncodedString() {
            return "data:image/jpeg;base64,\(base64)"
        }
        return nil
    }
    
    func pngDataURL() -> String? {
        if let base64 = pngData()?.base64EncodedString() {
            return "data:image/png;base64,\(base64)"
        }
        return nil
    }
}

extension UIImage {
    private func sizeForFit(_ size: CGSize) -> CGSize {
        let wRatio = size.width / self.size.width
        let hRatio = size.height / self.size.height
        if wRatio > hRatio {
            return CGSize(width: self.size.width * hRatio, height: size.height)
        } else {
            return CGSize(width: size.width, height: self.size.height * wRatio)
        }
    }
    
    private func write(to url: URL, quality: CGFloat? = nil) -> Error? {
        do {
            if let quality = quality {
                try jpegData(compressionQuality: quality)?.write(to: url)
            } else {
                try pngData()?.write(to: url)
            }
            return nil
        } catch let error {
            return error
        }
    }
}
