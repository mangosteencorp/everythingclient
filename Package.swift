// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "everythingclient",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EverythingClient",
            targets: ["everythingclient"]),
        // Targets need to be exposed as libraries so Preview works
        .library(
            name: "TMDB",
            targets: ["TMDB"]),
        // Now Playign
        .library(
            name: "TMDB_Dimilian_MVVM",
            targets: ["TMDB_Dimilian_MVVM"]),
        // Upcoming
        .library(
            name: "TMDB_Dimilian_clean",
            targets: ["TMDB_Dimilian_clean"]),
        
        // Sign in
        
        .library(name: "TMDB_dancarvajc_Login",  targets: ["TMDB_dancarvajc_Login"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/kean/Nuke.git", from: "12.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "everythingclient", dependencies: ["TMDB"]),
        .testTarget(
            name: "everythingclientTests",
            dependencies: ["everythingclient"]),
        
            .target(
                name: "TMDB",
                dependencies: ["TMDB_Dimilian_MVVM",
                               "TMDB_Dimilian_clean",
                               "TMDB_dancarvajc_Login"
                              ]),
        .target(
            name: "TMDB_Dimilian_MVVM",
            resources: [
                .process("Resources")
            ]),
        .target(
            name: "TMDB_Dimilian_clean",
            dependencies: ["Swinject"],
            swiftSettings: [.define("DEBUG", .when(configuration: .debug))]
        ),
        .testTarget(
            name: "TMDB_Dimilian_clean_tests",
            dependencies: ["TMDB_Dimilian_clean"]),
        
        .target(
            name: "TMDB_dancarvajc_Login",
            dependencies: [
                "KeychainAccess",
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "NukeUI", package: "Nuke")
            ],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
// icon: https://claude.ai/chat/84b7ac4c-75d9-4778-bc18-f24711a64d4b
