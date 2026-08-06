// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "isar_community_flutter_libs",
    platforms: [
        .iOS("11.0")
    ],
    products: [
        .library(
            name: "isar-community-flutter-libs",
            targets: ["isar_community_flutter_libs"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "isar",
            path: "isar.xcframework"
        ),
        .target(
            name: "isar_community_flutter_libs",
            dependencies: ["isar"],
            path: "Sources/isar_community_flutter_libs",
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy")
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("include/isar_community_flutter_libs")
            ]
        )
    ]
)
