//
//  DW_TLAssetsCollection.swift
//  DW_TLPhotosPicker
//
//  Created by wade.hawk on 2017. 4. 18..
//  Copyright © 2017년 wade.hawk. All rights reserved.
//

import Foundation
import Photos
import PhotosUI
import MobileCoreServices



extension DW_TLPHAsset: Equatable {
    public static func ==(lhs: DW_TLPHAsset, rhs: DW_TLPHAsset) -> Bool {
        guard let lphAsset = lhs.phAsset, let rphAsset = rhs.phAsset else { return false }
        return lphAsset.localIdentifier == rphAsset.localIdentifier
    }
}

extension Array {
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
}

public struct DW_TLAssetsCollection {
    var phAssetCollection: PHAssetCollection? = nil
    var fetchResult: PHFetchResult<PHAsset>? = nil
    var useCameraButton: Bool = false
    var recentPosition: CGPoint = CGPoint.zero
    var title: String
    var localIdentifier: String
    public var sections: [(title: String, assets: [DW_TLPHAsset])]? = nil
    var count: Int {
        get {
            guard let count = self.fetchResult?.count, count > 0 else { return self.useCameraButton ? 1 : 0 }
            return count + (self.useCameraButton ? 1 : 0)
        }
    }
    var assetCount: Int {
        get {
            return self.fetchResult?.count ?? 0
        }
    }
    
    init(collection: PHAssetCollection) {
        self.phAssetCollection = collection
        self.title = collection.localizedTitle ?? ""
        self.localIdentifier = collection.localIdentifier
    }
    
    func getAsset(at index: Int) -> PHAsset? {
        if self.useCameraButton && index == 0 { return nil }
        let index = index - (self.useCameraButton ? 1 : 0)
        guard let result = self.fetchResult, index < result.count else { return nil }
        return result.object(at: max(index,0))
    }
    
    func getTLAsset(at indexPath: IndexPath) -> DW_TLPHAsset? {
        let isCameraRow = self.useCameraButton && indexPath.section == 0 && indexPath.row == 0
        if isCameraRow {
            return nil
        }
        if let sections = self.sections {
            let index = indexPath.row - ((self.useCameraButton && indexPath.section == 0) ? 1 : 0)
            let result = sections[safe: indexPath.section]
            return result?.assets[safe: index]
        }else {
            var index = indexPath.row
            index = index - (self.useCameraButton ? 1 : 0)
            guard let result = self.fetchResult, index < result.count else { return nil }
            return DW_TLPHAsset(asset: result.object(at: max(index,0)))
        }
    }
    
    func findIndex(phAsset: PHAsset) -> IndexPath? {
        guard let sections = self.sections else {
            return nil
        }
        for (offset, section) in sections.enumerated() {
            if let index = section.assets.firstIndex(where: { $0.phAsset == phAsset }) {
                return IndexPath(row: index, section: offset)
            }
        }
        return nil
    }
    
    mutating func reloadSection(groupedBy: PHFetchedResultGroupedBy) {
        var groupedSections = self.section(groupedBy: groupedBy)
        if self.useCameraButton {
            groupedSections.insert(("camera",[DW_TLPHAsset(asset: nil)]), at: 0)
        }
        self.sections = groupedSections
    }
    
    static func ==(lhs: DW_TLAssetsCollection, rhs: DW_TLAssetsCollection) -> Bool {
        return lhs.localIdentifier == rhs.localIdentifier
    }
}

extension UIImage {
    func upOrientationImage() -> UIImage? {
        switch imageOrientation {
        case .up:
            return self
        default:
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            draw(in: CGRect(origin: .zero, size: size))
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return result
        }
    }
}
