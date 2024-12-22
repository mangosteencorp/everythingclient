// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
// MLS=Movie List, MDT=Movie details, 
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
            name: "TMDB_MVVM_MLS",
            targets: ["TMDB_MVVM_MLS"]),
        // Upcoming
        .library(
            name: "TMDB_clean_MLS",
            targets: ["TMDB_clean_MLS"]),
        
        // Sign in
        
        .library(name: "TMDB_MVVM_Login",  targets: ["TMDB_MVVM_Login"]),
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
            dependencies: ["TMDB_MVVM_MLS",
                            "TMDB_clean_MLS",
                            "TMDB_MVVM_Login"
                            ]),
        .target(name: "TMDB_Shared_Backend"),
        .target(name: "TMDB_Shared_UI"),
        .target(
            name: "TMDB_MVVM_MLS",
            resources: [
                .process("Resources")
            ]),
        .target(
            name: "TMDB_clean_MLS",
            dependencies: ["Swinject"],
            swiftSettings: [.define("DEBUG", .when(configuration: .debug))]
        ),
        .testTarget(
            name: "TMDB_clean_MLS_tests",
            dependencies: ["TMDB_clean_MLS"]),
        
        .target(
            name: "TMDB_MVVM_Login",
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

