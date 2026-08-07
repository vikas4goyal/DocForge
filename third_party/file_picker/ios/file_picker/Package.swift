// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "file_picker",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "file-picker", targets: ["file_picker"])
    ],
    // DocScanly uses file_picker only for documents, directories, and saves.
    // Gallery import is provided by image_picker. Keeping file_picker's media
    // backend here would pull in DKCamera, whose optional GPS-metadata support
    // references CLLocationManager and causes App Store Connect to require a
    // location purpose string even though the app never enables that feature.
    dependencies: [],
    targets: [
        .target(
            name: "file_picker",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            cSettings: [
                .headerSearchPath("include/file_picker"),
                .define("PICKER_DOCUMENT")
            ]
        )
    ]
)
