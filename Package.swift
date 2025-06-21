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
            name: "TMDB_Movie_Feed",
            targets: ["TMDB_Movie_Feed"]
        ),
        // Upcoming movies
        .library(
            name: "TMDB_TVFeed",
            targets: ["TMDB_TVFeed"]
        ),
        // Profile page
        .library(
            name: "TMDB_Profile",
            targets: ["TMDB_Profile"]
        ),
        .library(
            name: "TMDB_MovieDetail",
            targets: ["TMDB_MovieDetail"]
        ),
        .library(name: "Pokedex", targets: ["Pokedex"]),
        // for building purpose
        .library(name: "Pokedex_Pokelist", targets: ["Pokedex_Pokelist"]),
        .library(name: "Pokedex_Detail", targets: ["Pokedex_Detail"]),
        .library(name: "Pokedex_Shared_Backend", targets: ["Pokedex_Shared_Backend"]),
        .library(name: "TMDB_TVShowDetail", targets: ["TMDB_TVShowDetail"]),

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
            dependencies: [
                "TMDB",
                "Pokedex",
                "CoreFeatures",
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
            ]
        ),
        .testTarget(
            name: "everythingclientTests",
            dependencies: ["everythingclient"]
        ),

        // MARK: TMDB

        .target(
            name: "TMDB",
            dependencies: [
                "TMDB_Movie_Feed",
                "TMDB_TVFeed",
                "TMDB_Profile",
                "TMDB_Shared_UI",
                "TMDB_MovieDetail",
                "TMDB_TVShowDetail",
                "Swinject",
            ]
        ),
        .target(
            name: "TMDB_Shared_Backend",
            dependencies: ["Swinject"]
        ),
        .target(name: "TMDB_Shared_UI",
                dependencies: ["Shared_UI_Support"]),
        // Detail page
        .target(
            name: "TMDB_MovieDetail",
            dependencies: [
                "TMDB_Shared_UI",
                "Swinject",
                "TMDB_Shared_Backend",
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "TMDB_TVShowDetail",
            dependencies: [
                "TMDB_Shared_Backend",
            ]
        ),
        // Movie list
        .target(
            name: "TMDB_Movie_Feed",
            dependencies: [
                "TMDB_Shared_UI",
                "TMDB_Shared_Backend",
                "CoreFeatures",
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "TMDB_Movie_Feed_Tests",
            dependencies: ["TMDB_Movie_Feed", "ViewInspector", "Tests_Shared_Helpers"],
            resources: [.process("Resources")]
        ),
        // TV show feed - clean architecture
        .target(
            name: "TMDB_TVFeed",
            dependencies: ["Swinject", "TMDB_Shared_UI", "TMDB_Shared_Backend", "CoreFeatures"],
            swiftSettings: [.define("DEBUG", .when(configuration: .debug))]
        ),
        .testTarget(
            name: "TMDB_TVFeed_Tests",
            dependencies: ["TMDB_TVFeed", "Tests_Shared_Helpers", "ViewInspector"]
        ),

        .target(
            name: "TMDB_Profile",
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
                "CoreFeatures",
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
            name: "CoreFeatures"
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
