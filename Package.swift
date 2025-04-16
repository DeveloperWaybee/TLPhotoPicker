// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DW_TLPhotoPicker",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "DW_TLPhotoPicker",
            targets: ["DW_TLPhotoPicker"]
        ),
    ],
    targets: [
        .target(
            name: "DW_TLPhotoPicker",
            path: "DW_TLPhotoPicker",
            exclude: [
                "Classes/DW_TLBundle.swift",
                "DW_TLPhotoPicker/Info.plist",
                "DW_TLPhotoPickerController.bundle"
            ],
            resources: [
                .process("Classes/DW_TLCollectionTableViewCell.xib"),
                .process("Classes/DW_TLPhotoCollectionViewCell.xib"),
                .process("Classes/DW_TLPhotosPickerViewController.xib"),
                .process("Assets.xcassets")
            ]
        )
    ]
)
