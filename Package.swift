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
        .library(name: "TMDB_AlonsoUpcomingMovies_og", type: .dynamic, targets: ["TMDB_AlonsoUpcomingMovies_og"]),
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
                               "TMDB_Dimilian_clean",
                               "TMDB_AlonsoUpcomingMovies_og"]),
        .target(
            name: "TMDB_Dimilian_MVVM"),
        .target(
            // https://claude.ai/chat/a8980734-bb2b-497b-afcd-ff34306e1392
            name: "TMDB_Dimilian_clean",
            dependencies: ["Swinject"]),
        
        .target(
            name: "TMDB_AlonsoUpcomingMovies_og"
            // https://claude.ai/chat/7b9a2446-c213-4685-b290-1d6e92bca1bc
        ),
    ]
)
// icon: https://claude.ai/chat/84b7ac4c-75d9-4778-bc18-f24711a64d4b
