// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TeslaBLEKeyKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "TeslaBLEKeyKit",
            targets: ["TeslaBLEKeyKit"]
        ),
        .library(
            name: "TeslaBLEKeyKitCore",
            targets: ["TeslaBLEKeyKitCore"]
        ),
        .library(
            name: "TeslaBLEKeyKitCrypto",
            targets: ["TeslaBLEKeyKitCrypto"]
        ),
        .library(
            name: "TeslaBLEKeyKitBLE",
            targets: ["TeslaBLEKeyKitBLE"]
        ),
        .executable(
            name: "TeslaBLEKeyKitExample",
            targets: ["TeslaBLEKeyKitExample"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.28.2"),
    ],
    targets: [
        .target(
            name: "TeslaBLEKeyKitCore",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ]
        ),
        .target(
            name: "TeslaBLEKeyKitCrypto",
            dependencies: ["TeslaBLEKeyKitCore"]
        ),
        .target(
            name: "TeslaBLEKeyKitBLE",
            dependencies: ["TeslaBLEKeyKitCore"],
            linkerSettings: [
                .linkedFramework("CoreBluetooth", .when(platforms: [.iOS, .macOS, .tvOS, .watchOS, .visionOS])),
            ]
        ),
        .target(
            name: "TeslaBLEKeyKit",
            dependencies: [
                "TeslaBLEKeyKitCore",
                "TeslaBLEKeyKitCrypto",
                "TeslaBLEKeyKitBLE",
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ],
            exclude: [
                "Protos",
            ],
            linkerSettings: [
                .linkedFramework("Security"),
            ]
        ),
        .executableTarget(
            name: "TeslaBLEKeyKitExample",
            dependencies: ["TeslaBLEKeyKit"]
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
