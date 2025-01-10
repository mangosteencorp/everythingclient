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
        // Upcoming movies
        .library(
            name: "TMDB_clean_MLS",
            targets: ["TMDB_clean_MLS"]),
        // Profile page
        .library(
            name: "TMDB_Clean_Profile",
            targets: ["TMDB_Clean_Profile"]),
        .library(
            name: "TMDB_MVVM_Detail",
            targets: ["TMDB_MVVM_Detail"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
        .package(url: "https://github.com/kean/Nuke.git", from: "12.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0"),
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
                               "TMDB_Clean_Profile",
                               "TMDB_Shared_UI",
                               "TMDB_MVVM_Detail",
                               "Swinject"
                              ]),
        .target(name: "TMDB_Shared_Backend",
                dependencies: ["Swinject"]),
        .target(name: "TMDB_Shared_UI"),
        .target(name: "TMDB_MVVM_Detail", dependencies: [
            "TMDB_Shared_UI",
            "Swinject",
            "TMDB_Shared_Backend"],
                resources: [
                    .process("Resources")
                ]),
        .target(
            name: "TMDB_MVVM_MLS",
            dependencies: ["TMDB_Shared_UI"],
            resources: [
                .process("Resources")
            ]),
        .target(
            name: "TMDB_clean_MLS",
            dependencies: ["Swinject", "TMDB_Shared_UI"],
            swiftSettings: [.define("DEBUG", .when(configuration: .debug))]
        ),
        .testTarget(
            name: "TMDB_clean_MLS_tests",
            dependencies: ["TMDB_clean_MLS"]),
        .target(
            name: "TMDB_Clean_Profile",
            dependencies: ["TMDB_Shared_Backend", "Swinject", "Kingfisher"]
        ),
        .testTarget(
            name: "TMDB_Shared_Backend_Tests",
            dependencies: ["TMDB_Shared_Backend"],
            resources: [.process("Resources")] // needed for Bundle.module
        ),
    ]
)

