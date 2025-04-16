//
//  DW_TLBundle.swift
//  Pods
//
//  Created by wade.hawk on 2017. 5. 9..
//
//

import UIKit

open class DW_TLBundle {
    open class func podBundleImage(named: String) -> UIImage? {
        let podBundle = Bundle(for: DW_TLBundle.self)
        if let url = podBundle.url(forResource: "DW_TLPhotoPickerController", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return UIImage(named: named, in: bundle, compatibleWith: nil)
        }
        return nil
    }
    
    class func bundle() -> Bundle {
        let podBundle = Bundle(for: DW_TLBundle.self)
        if let url = podBundle.url(forResource: "DW_TLPhotoPicker", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return bundle ?? podBundle
        }
        return podBundle
    }
}
