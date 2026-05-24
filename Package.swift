// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TeslaBLEKeyKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "TeslaBLEKeyKit",
            targets: ["TeslaBLEKeyKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.28.2"),
    ],
    targets: [
        .target(
            name: "TeslaBLEKeyKit",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            exclude: [
                "Protos",
            ],
            linkerSettings: [
                .linkedFramework("CoreBluetooth"),
                .linkedFramework("Security"),
            ]
        ),
        .testTarget(
            name: "TeslaBLEKeyKitTests",
            dependencies: ["TeslaBLEKeyKit"]
        ),
        .testTarget(
            name: "TeslaBLEKeyKitXCTests",
            dependencies: ["TeslaBLEKeyKit"],
            path: "Tests/TeslaBLEKeyKitXCTests"
        ),
    ]
)
