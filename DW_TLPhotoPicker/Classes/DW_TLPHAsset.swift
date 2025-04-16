//
//  DW_TLPHAsset.swift
//  DW_TLPhotoPicker
//
//  Created by Bhavneet Singh on 16/04/25.
//


import Foundation
import Photos
import PhotosUI
import MobileCoreServices

public struct DW_TLPHAsset {
    enum CloudDownloadState {
        case ready, progress, complete, failed
    }
    
    public enum AssetType {
        case photo, video, livePhoto
    }
    
    public enum ImageExtType: String {
        case png, jpg, gif, heic
    }
    
    var state = CloudDownloadState.ready
    public var phAsset: PHAsset? = nil
    //Bool to check if DW_TLPHAsset returned is created using camera.
    public var isSelectedFromCamera = false
    public var selectedOrder: Int = 0
    public var type: AssetType {
        get {
            guard let phAsset = self.phAsset else { return .photo }
            if phAsset.mediaSubtypes.contains(.photoLive) {
                return .livePhoto
            }else if phAsset.mediaType == .video {
                return .video
            }else {
                return .photo
            }
        }
    }
    
    public var fullResolutionImage: UIImage? {
        get {
            guard let phAsset = self.phAsset else { return nil }
            return DW_TLPhotoLibrary.fullResolutionImageData(asset: phAsset)
        }
    }
    
    public func extType(defaultExt: ImageExtType = .png) -> ImageExtType {
        guard let fileName = self.originalFileName,
              let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let extention = URL(string: encodedFileName)?.pathExtension.lowercased() else {
                  return defaultExt
              }
        return ImageExtType(rawValue: extention) ?? defaultExt
    }
    
    @discardableResult
    public func cloudImageDownload(progressBlock: @escaping (Double) -> Void, completionBlock:@escaping (UIImage?)-> Void ) -> PHImageRequestID? {
        guard let phAsset = self.phAsset else { return nil }
        return DW_TLPhotoLibrary.cloudImageDownload(asset: phAsset, progressBlock: progressBlock, completionBlock: completionBlock)
    }
    
    public var originalFileName: String? {
        get {
            guard let phAsset = self.phAsset,let resource = PHAssetResource.assetResources(for: phAsset).first else { return nil }
            return resource.originalFilename
        }
    }
    
    public func photoSize(options: PHImageRequestOptions? = nil ,completion: @escaping ((Int)->Void), livePhotoVideoSize: Bool = false) {
        guard let phAsset = self.phAsset, self.type == .photo || self.type == .livePhoto else { completion(-1); return }
        var resource: PHAssetResource? = nil
        if phAsset.mediaSubtypes.contains(.photoLive) == true, livePhotoVideoSize {
            resource = PHAssetResource.assetResources(for: phAsset).filter { $0.type == .pairedVideo }.first
        }else {
            resource = PHAssetResource.assetResources(for: phAsset).filter { $0.type == .photo }.first
        }
        if let fileSize = resource?.value(forKey: "fileSize") as? Int {
            completion(fileSize)
        }else {
            PHImageManager.default().requestImageData(for: phAsset, options: nil) { (data, uti, orientation, info) in
                var fileSize = -1
                if let data = data {
                    let bcf = ByteCountFormatter()
                    bcf.countStyle = .file
                    fileSize = data.count
                }
                DispatchQueue.main.async {
                    completion(fileSize)
                }
            }
        }
    }
    
    public func videoSize(options: PHVideoRequestOptions? = nil, completion: @escaping ((Int)->Void)) {
        guard let phAsset = self.phAsset, self.type == .video else {  completion(-1); return }
        let resource = PHAssetResource.assetResources(for: phAsset).filter { $0.type == .video }.first
        if let fileSize = resource?.value(forKey: "fileSize") as? Int {
            completion(fileSize)
        }else {
            PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { (avasset, audioMix, info) in
                func fileSize(_ url: URL?) -> Int? {
                    do {
                        guard let fileSize = try url?.resourceValues(forKeys: [.fileSizeKey]).fileSize else { return nil }
                        return fileSize
                    }catch { return nil }
                }
                var url: URL? = nil
                if let urlAsset = avasset as? AVURLAsset {
                    url = urlAsset.url
                }else if let sandboxKeys = info?["PHImageFileSandboxExtensionTokenKey"] as? String, let path = sandboxKeys.components(separatedBy: ";").last {
                    url = URL(fileURLWithPath: path)
                }
                let size = fileSize(url) ?? -1
                DispatchQueue.main.async {
                    completion(size)
                }
            }
        }
    }
    
    func MIMEType(_ url: URL?) -> String? {
        guard let ext = url?.pathExtension else { return nil }
        if !ext.isEmpty {
            let UTIRef = UTTypeCreatePreferredIdentifierForTag("public.filename-extension" as CFString, ext as CFString, nil)
            let UTI = UTIRef?.takeUnretainedValue()
            UTIRef?.release()
            if let UTI = UTI {
                guard let MIMETypeRef = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType) else { return nil }
                let MIMEType = MIMETypeRef.takeUnretainedValue()
                MIMETypeRef.release()
                return MIMEType as String
            }
        }
        return nil
    }
    
    private func tempCopyLivePhotos(phAsset: PHAsset,
                                    livePhotoRequestOptions: PHLivePhotoRequestOptions? = nil,
                                    localURL: URL,
                                    completionBlock:@escaping (() -> Void)) -> PHImageRequestID? {
        var requestOptions = PHLivePhotoRequestOptions()
        if let options = livePhotoRequestOptions {
            requestOptions = options
        }else {
            requestOptions.isNetworkAccessAllowed = true
        }
        return PHImageManager.default().requestLivePhoto(for: phAsset,
                                                         targetSize: UIScreen.main.bounds.size,
                                                         contentMode: .default,
                                                         options: requestOptions)
        { (livePhotos, infoDict) in
            if let livePhotos = livePhotos {
                let assetResources = PHAssetResource.assetResources(for: livePhotos)
                assetResources.forEach { (resource) in
                    if resource.type == .pairedVideo {
                        PHAssetResourceManager.default().writeData(for: resource, toFile: localURL, options: nil) { (error) in
                            DispatchQueue.main.async {
                                completionBlock()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @discardableResult
    //convertLivePhotosToJPG
    // false : If you want mov file at live photos
    // true  : If you want png file at live photos ( HEIC )
    public func tempCopyMediaFile(videoRequestOptions: PHVideoRequestOptions? = nil,
                                  imageRequestOptions: PHImageRequestOptions? = nil,
                                  livePhotoRequestOptions: PHLivePhotoRequestOptions? = nil,
                                  exportPreset: String = AVAssetExportPresetHighestQuality,
                                  convertLivePhotosToJPG: Bool = false,
                                  progressBlock:((Double) -> Void)? = nil,
                                  completionBlock:@escaping ((URL,String) -> Void)) -> PHImageRequestID? {
        guard let phAsset = self.phAsset else { return nil }
        var type: PHAssetResourceType? = nil
        if phAsset.mediaSubtypes.contains(.photoLive) == true, convertLivePhotosToJPG == false {
            type = .pairedVideo
        }else {
            type = phAsset.mediaType == .video ? .video : .photo
        }
        guard let resource = (PHAssetResource.assetResources(for: phAsset).filter{ $0.type == type }).first else { return nil }
        let fileName = resource.originalFilename
        var writeURL: URL? = nil
        if #available(iOS 10.0, *) {
            writeURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName)")
        } else {
            writeURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("\(fileName)")
        }
        guard var localURL = writeURL,var mimetype = MIMEType(writeURL) else { return nil }
        if type == .pairedVideo {
            return tempCopyLivePhotos(phAsset: phAsset,
                                      livePhotoRequestOptions: livePhotoRequestOptions,
                                      localURL: localURL,
                                      completionBlock: { completionBlock(localURL, mimetype) })
        }
        switch phAsset.mediaType {
        case .video:
            var requestOptions = PHVideoRequestOptions()
            if let options = videoRequestOptions {
                requestOptions = options
            }else {
                requestOptions.isNetworkAccessAllowed = true
            }
            //iCloud download progress
            requestOptions.progressHandler = { (progress, error, stop, info) in
                DispatchQueue.main.async {
                    progressBlock?(progress)
                }
            }
            return PHImageManager.default().requestExportSession(forVideo: phAsset,
                                                                 options: requestOptions,
                                                                 exportPreset: exportPreset)
            { (session, infoDict) in
                session?.outputURL = localURL
                session?.outputFileType = AVFileType.mov
                session?.exportAsynchronously(completionHandler: {
                    DispatchQueue.main.async {
                        completionBlock(localURL, mimetype)
                    }
                })
            }
        case .image:
            var requestOptions = PHImageRequestOptions()
            if let options = imageRequestOptions {
                requestOptions = options
            }else {
                requestOptions.isNetworkAccessAllowed = true
            }
            //iCloud download progress
            requestOptions.progressHandler = { (progress, error, stop, info) in
                DispatchQueue.main.async {
                    progressBlock?(progress)
                }
            }
            return PHImageManager.default().requestImageData(for: phAsset,
                                                             options: requestOptions)
            { (data, uti, orientation, info) in
                do {
                    var data = data
                    let needConvertLivePhotoToJPG = phAsset.mediaSubtypes.contains(.photoLive) == true && convertLivePhotosToJPG == true
                    if needConvertLivePhotoToJPG {
                        let name = localURL.deletingPathExtension().lastPathComponent
                        localURL.deleteLastPathComponent()
                        localURL.appendPathComponent("\(name).jpg")
                        mimetype = "image/jpeg"
                    }
                    if needConvertLivePhotoToJPG, let imgData = data, let rawImage = UIImage(data: imgData)?.upOrientationImage() {
                        data = rawImage.jpegData(compressionQuality: 1)
                    }
                    try data?.write(to: localURL)
                    DispatchQueue.main.async {
                        completionBlock(localURL, mimetype)
                    }
                }catch { }
            }
        default:
            return nil
        }
    }
    
    private func videoFilename(phAsset: PHAsset) -> URL? {
        guard let resource = (PHAssetResource.assetResources(for: phAsset).filter{ $0.type == .video }).first else {
            return nil
        }
        var writeURL: URL?
        let fileName = resource.originalFilename
        if #available(iOS 10.0, *) {
            writeURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName)")
        } else {
            writeURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("\(fileName)")
        }
        return writeURL
    }
    
    //Apparently, This is not the only way to export video.
    //There is many way that export a video.
    //This method was one of them.
    public func exportVideoFile(options: PHVideoRequestOptions? = nil,
                                outputURL: URL? = nil,
                                outputFileType: AVFileType = .mov,
                                progressBlock:((Double) -> Void)? = nil,
                                completionBlock:@escaping ((URL,String) -> Void)) {
        guard
            let phAsset = self.phAsset,
            phAsset.mediaType == .video,
            let writeURL = outputURL ?? videoFilename(phAsset: phAsset),
            let mimetype = MIMEType(writeURL)
            else {
                return
        }
        var requestOptions = PHVideoRequestOptions()
        if let options = options {
            requestOptions = options
        }else {
            requestOptions.isNetworkAccessAllowed = true
        }
        requestOptions.progressHandler = { (progress, error, stop, info) in
            DispatchQueue.main.async {
                progressBlock?(progress)
            }
        }
        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: requestOptions) { (avasset, avaudioMix, infoDict) in
            guard let avasset = avasset else {
                return
            }
            let exportSession = AVAssetExportSession.init(asset: avasset, presetName: AVAssetExportPresetHighestQuality)
            exportSession?.outputURL = writeURL
            exportSession?.outputFileType = outputFileType
            exportSession?.exportAsynchronously(completionHandler: {
                completionBlock(writeURL, mimetype)
            })
        }
    }
    
    public init(asset: PHAsset?) {
        self.phAsset = asset
    }

    public static func asset(with localIdentifier: String) -> DW_TLPHAsset? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        return DW_TLPHAsset(asset: fetchResult.firstObject)
    }
}
