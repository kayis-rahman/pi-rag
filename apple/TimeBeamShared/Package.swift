// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "TimeBeamShared",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "TimeBeamShared",
            targets: ["TimeBeamShared"]
        )
    ],
    targets: [
        .target(
            name: "TimeBeamShared",
            dependencies: []
        )
    ]
)
