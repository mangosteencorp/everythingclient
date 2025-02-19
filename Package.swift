// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
// MLS=Movie List, MDT=Movie details,
import PackageDescription

let package = Package(
    name: "everythingclient",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
        //.macOS(.v11),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EverythingClient",
            targets: ["everythingclient"]
        ),
        // Targets need to be exposed as libraries so Preview works
        .library(
            name: "TMDB",
            targets: ["TMDB"]
        ),
        // Now Playign
        .library(
            name: "TMDB_MVVM_MLS",
            targets: ["TMDB_MVVM_MLS"]
        ),
        // Upcoming movies
        .library(
            name: "TMDB_clean_MLS",
            targets: ["TMDB_clean_MLS"]
        ),
        // Profile page
        .library(
            name: "TMDB_Clean_Profile",
            targets: ["TMDB_Clean_Profile"]
        ),
        .library(
            name: "TMDB_MVVM_Detail",
            targets: ["TMDB_MVVM_Detail"]
        ),
        .library(name: "Pokedex", targets: ["Pokedex"]),
        // for building purpose
        .library(name: "Pokedex_Pokelist", targets: ["Pokedex_Pokelist"]),
        .library(name: "Pokedex_Detail", targets: ["Pokedex_Detail"]),
        .library(name: "Pokedex_Shared_Backend", targets: ["Pokedex_Shared_Backend"]),

    ],
    dependencies: [
        .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.0"),
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.58.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.0.0"),
        .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.0"),
        .package(
            url: "https://github.com/apollographql/apollo-ios.git",
            .upToNextMajor(from: "1.0.0")
        ),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.6.0"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", .upToNextMajor(from: "5.0.1")),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.4.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "everythingclient",
            dependencies: ["TMDB", "Pokedex"]
        ),
        .testTarget(
            name: "everythingclientTests",
            dependencies: ["everythingclient"]
        ),

        // MARK: TMDB

        .target(
            name: "TMDB",
            dependencies: [
                "TMDB_MVVM_MLS",
                "TMDB_clean_MLS",
                "TMDB_Clean_Profile",
                "TMDB_Shared_UI",
                "TMDB_MVVM_Detail",
                "Swinject",
            ]
        ),
        .target(
            name: "TMDB_Shared_Backend",
            dependencies: ["Swinject"]
        ),
        .target(name: "TMDB_Shared_UI"),
        // Detail page
        .target(
            name: "TMDB_MVVM_Detail",
            dependencies: [
                "TMDB_Shared_UI",
                "Swinject",
                "TMDB_Shared_Backend",
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        // Movie list
        .target(
            name: "TMDB_MVVM_MLS",
            dependencies: ["TMDB_Shared_UI", "TMDB_Shared_Backend"],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "TMDB_MVVM_MLS_Tests",
            dependencies: ["TMDB_MVVM_MLS", "ViewInspector", "Tests_Shared_Helpers"],
            resources: [.process("Resources")]
        ),
        // TV show feed - clean architecture
        .target(
            name: "TMDB_clean_MLS",
            dependencies: ["Swinject", "TMDB_Shared_UI", "TMDB_Shared_Backend"],
            swiftSettings: [.define("DEBUG", .when(configuration: .debug))]
        ),
        .testTarget(
            name: "TMDB_clean_MLS_tests",
            dependencies: ["TMDB_clean_MLS", "Tests_Shared_Helpers", "ViewInspector"]
        ),

        .target(
            name: "TMDB_Clean_Profile",
            dependencies: ["TMDB_Shared_Backend", "Swinject", "Kingfisher", "Shared_UI_Support", "TMDB_Shared_UI"]
        ),

        .testTarget(
            name: "TMDB_Shared_Backend_Tests",
            dependencies: ["TMDB_Shared_Backend"],
            resources: [.process("Resources")] // needed for Bundle.module
        ),

        // MARK: Pokedex

        .target(
            name: "Pokedex",
            dependencies: [
                "Pokedex_Pokelist",
                "Pokedex_Detail",
                "Pokedex_Shared_Backend",
            ]
        ),
        .target(
            name: "Pokedex_Pokelist",
            dependencies: [
                "Kingfisher",
                "Pokedex_Shared_Backend",
                "Shared_UI_Support",
            ]
        ),
        .target(
            name: "Pokedex_Detail",
            dependencies: [
                "Kingfisher",
                "Pokedex_Shared_Backend",
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "SnapKit", package: "SnapKit"),
                "Shared_UI_Support",
            ]
        ),
        .target(
            name: "Pokedex_Shared_Backend",
            dependencies: [
                .product(name: "Apollo", package: "apollo-ios"),
            ]
        ),

        // MARK: Common

        .target(
            name: "Tests_Shared_Helpers",
            path: "Tests/Tests_Shared_Helpers"
        ),
        .target(
            name: "Shared_UI_Support"
        ),
        .target(
            name: "Core_BaaS_Serverless",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            ]
        ),
    ]
)
for target in package.targets {
  target.linkerSettings = target.linkerSettings ?? []
  target.linkerSettings?.append(
    .unsafeFlags([
      "-ObjC",
    ])
  )
}
