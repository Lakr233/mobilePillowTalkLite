// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NMSSH",
    products: [
        .library(name: "NMSSH", targets: ["NMSSH"])
    ],
    dependencies: [
        .package(name: "CSSH", path: "../CSSH"),
    ],
	targets: [
        .target(name: "NMSSH",
                dependencies: ["CSSH"],
                path: "NMSSH")
 	]
)
