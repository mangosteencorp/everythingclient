// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BrowserKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "Common",
            targets: ["Common"]),
        .library(
            name: "Redux",
            targets: ["Redux"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/AliSoftware/Dip.git",
            exact: "7.1.1"),
        .package(
            url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git",
            exact: "2.1.1"),
        .package(
            url: "https://github.com/getsentry/sentry-cocoa.git",
            exact: "9.10.0"),
    ],
    targets: [
        .target(
            name: "Common",
            dependencies: ["Dip",
                           "SwiftyBeaver",
                           .product(name: "Sentry-Dynamic", package: "sentry-cocoa")],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]
        ),
        .target(
            name: "Redux",
            dependencies: ["Common"],
            swiftSettings: [
                .unsafeFlags(["-enable-testing"]),
            ]),
        .testTarget(
            name: "ReduxTests",
            dependencies: ["Redux"],
            swiftSettings: [
            ]
        ),
    ]
)
