// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GCDWebServers",
    products: [
        .library(
            name: "GCDWebServers",
            targets: ["GCDWebServers"]),
    ],
    targets: [
        .target(
            name: "GCDWebServers",
            dependencies: [],
            path: ".",
            exclude: [
                "Package.swift",
                "LICENSE"
            ],
            resources: [
                .copy("GCDWebUploader/GCDWebUploader.bundle"),
            ],
            cSettings:[
                .headerSearchPath("GCDWebServer/Core"),
                .headerSearchPath("GCDWebServer/Requests"),
                .headerSearchPath("GCDWebServer/Responses"),
            ]),
    ]
)
