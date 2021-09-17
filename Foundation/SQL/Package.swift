// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SQLite",
    products: [.library(name: "SQLite", targets: ["SQLite"])],
    targets: [
        .target(name: "SQLite", dependencies: ["SQLiteObjc"]),
        .target(name: "SQLiteObjc"),
    ]
)
