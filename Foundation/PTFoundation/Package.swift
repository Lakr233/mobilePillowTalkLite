// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PTFoundation",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_10),
        .tvOS(.v10),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "PTFoundation",
            type: .static,
            targets: ["PTFoundation"]
        ),
    ],
    dependencies: [
        .package(name: "NMSSH", path: "../NMSSH"),
        .package(name: "SQLite", path: "../SQL"),
    ],
    targets: [
        .target(
            name: "PTFoundation",
            dependencies: ["NMSSH", "SQLite"]
        ),
    ]
)
