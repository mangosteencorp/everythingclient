// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "everythingclient",
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
        .library(
            name: "TMDB_Dimilian_MVVM",
            targets: ["TMDB_Dimilian_MVVM"]),
        .library(
            name: "TMDB_Dimilian_clean",
            targets: ["TMDB_Dimilian_clean"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.0")
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
                           "TMDB_Dimilian_clean"]),
        .target(
            name: "TMDB_Dimilian_MVVM"),
        .target(
            name: "TMDB_Dimilian_clean",
            dependencies: ["Swinject"]),
    ]
)
