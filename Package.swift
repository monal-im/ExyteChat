// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Chat",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ExyteChat",
            targets: ["ExyteChat"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/exyte/MediaPicker.git",
            from: "3.3.2"
        ),
        .package(
            url: "https://github.com/exyte/ActivityIndicatorView",
            from: "2.0.0"
        ),
        .package(
            url: "https://github.com/exyte/SVGView.git",
            from: "1.0.6"
        ),
    ],
    targets: [
        .target(
            name: "ExyteChat",
            dependencies: [
                .product(name: "ExyteMediaPicker", package: "MediaPicker"),
                .product(name: "ActivityIndicatorView", package: "ActivityIndicatorView"),
                .product(name: "SVGView", package: "SVGView"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ExyteChatTests",
            dependencies: ["ExyteChat"]),
    ],
    swiftLanguageModes: [.v5]
)
