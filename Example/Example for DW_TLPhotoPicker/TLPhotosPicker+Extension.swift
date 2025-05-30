//
//  TLPhotosPicker+Extension.swift
//  TLPhotoPicker
//
//  Created by wade.hawk on 2017. 7. 24..
//  Copyright © 2017년 CocoaPods. All rights reserved.
//

import Foundation
import DW_TLPhotoPicker

extension DW_TLPhotosPickerViewController {
    class func custom(withTLPHAssets: (([DW_TLPHAsset]) -> Void)? = nil, didCancel: (() -> Void)? = nil) -> CustomPhotoPickerViewController {
        let picker = CustomPhotoPickerViewController(withTLPHAssets: withTLPHAssets, didCancel:didCancel)
        return picker
    }
    
    func wrapNavigationControllerWithoutBar() -> UINavigationController {
        let navController = UINavigationController(rootViewController: self)
        navController.navigationBar.isHidden = true
        return navController
    }
}
