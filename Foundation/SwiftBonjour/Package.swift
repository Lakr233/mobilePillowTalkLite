// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftBonjour",
    platforms: [.macOS(.v10_12),
                .iOS(.v10),
                .tvOS(.v10)],
    products: [
        .library(
            name: "SwiftBonjour",
            targets: ["SwiftBonjour"]),
    ],
    targets: [
        .target(
            name: "SwiftBonjour",
            dependencies: []),
    ]
)
