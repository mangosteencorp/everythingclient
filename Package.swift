// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
// MLS=Movie List, MDT=Movie details,
import Foundation
import PackageDescription

// MARK: - Optional private module (SampleKit)

//
// SampleKit is a private git submodule (git@github.com:quangDecember/SampleKit.git).
// A clone made without submodule access still creates an EMPTY `SampleKit/` directory,
// so probe for the nested manifest rather than the directory itself.
//
// Anchor on #filePath: the manifest's working directory is not guaranteed to be the
// package root. Gating here (not on a `url:` dependency) keeps SampleKit out of
// Package.resolved entirely, so contributors without access get a graph that simply
// omits it instead of a resolution failure.
//
// NOTE: SwiftPM caches compiled manifests. After initialising or removing the
// submodule, run `swift package reset` (Xcode: File > Packages > Reset Package Caches)
// or the previous graph may be reused.
let hasSampleKit = FileManager.default.fileExists(
    atPath: URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("SampleKit/Package.swift")
        .path
)

let sampleKitPackageDependency: [Package.Dependency] =
    hasSampleKit ? [.package(path: "SampleKit")] : []

let sampleKitTargetDependency: [Target.Dependency] =
    hasSampleKit ? [.product(name: "SampleKit", package: "SampleKit")] : []

// MARK: - Optional dependency (Swiftfin)

//
// The `swiftpm` branch of Swiftfin does not build with the Swift 6.4 toolchain
// (Xcode 27); that port lives on a separate branch. Until it lands, drop the
// dependency entirely on newer compilers so the rest of the package still builds.
//
// This must be `compiler(...)`, not `swift(...)`: the tools version above makes
// SwiftPM compile this manifest in Swift 5 language mode, so `#if swift(>=6.4)`
// would always be false regardless of the toolchain. `compiler(...)` reflects the
// actual toolchain version.
//
// Call sites guard their usage with `#if canImport(SwiftfinLib)`.
#if compiler(>=6.4)
let hasSwiftfin = false
#else
let hasSwiftfin = true
#endif

let swiftfinPackageDependency: [Package.Dependency] =
    hasSwiftfin ? [.package(url: "https://github.com/quangDecember/Swiftfin", branch: "swiftpm")] : []

let swiftfinTargetDependency: [Target.Dependency] =
    hasSwiftfin ? [.product(name: "SwiftfinLib", package: "Swiftfin")] : []

let package = Package(
    name: "everythingclient",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        //.macOS(.v11),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EverythingClient",
            targets: ["everythingclient"]
        ),
        .library(
            name: "everythingclient",
            targets: ["everythingclient"]
        ),
        // Targets need to be exposed as libraries so Preview works
        .library(
            name: "TMDB",
            targets: ["TMDB"]
        ),
        // Now Playing
        .library(
            name: "TMDB_Feed",
            targets: ["TMDB_Feed"]
        ),
        // Discover movies
        .library(
            name: "TMDB_Discover",
            targets: ["TMDB_Discover"]
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
        .library(
            name: "PhotoListViewer",
            targets: ["PhotoListViewer"]
        ),
        .library(
            name: "TMDB_Person",
            targets: ["TMDB_Person"]
        ),
        .library(
            name: "third_party",
            targets: ["third_party"]
        ),
        .library(name: "Pokedex", targets: ["Pokedex"]),
        // for building purpose
        .library(name: "Pokedex_Pokelist", targets: ["Pokedex_Pokelist"]),
        .library(name: "Pokedex_Detail", targets: ["Pokedex_Detail"]),
        .library(name: "Pokedex_Shared_Backend", targets: ["Pokedex_Shared_Backend"]),
        .library(name: "TMDB_TVShowDetail", targets: ["TMDB_TVShowDetail"]),
        .library(name: "Integration_test", targets: ["Integration_test"]),

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
    ] + sampleKitPackageDependency + swiftfinPackageDependency,
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "everythingclient",
            dependencies: [
                "TMDB",
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
                "TMDB_Feed",
                "TMDB_Discover",
                "TMDB_Profile",
                "TMDB_Shared_UI",
                "TMDB_MovieDetail",
                "TMDB_TVShowDetail",
                "TMDB_Person",
                "PhotoListViewer",
                "third_party",
                "Pokedex",
                "Swinject",
            ] + sampleKitTargetDependency
        ),
        .target(
            name: "TMDB_Shared_Backend",
            dependencies: ["Swinject"],
            // Keep the debug API key file on disk for local/DEBUG loading, but do not
            // compile/index it into the Swift module.
            exclude: ["Preview/DebugPreview.swift"]
        ),
        .target(
            name: "TMDB_Shared_UI",
            dependencies: [
                "TMDB_Shared_Backend",
                "Shared_UI_Support",
            ]
        ),
        // Detail page
        .target(
            name: "TMDB_MovieDetail",
            dependencies: [
                "TMDB_Shared_UI",
                "PhotoListViewer",
                "Swinject",
                "TMDB_Shared_Backend",
            ],
            resources: [
                .process("Resources"),
            ],
            linkerSettings: [
                .linkedFramework("MusicKit", .when(platforms: [.iOS, .macCatalyst])),
            ]
        ),
        .testTarget(
            name: "TMDB_MovieDetail_Tests",
            dependencies: ["TMDB_MovieDetail"]
        ),
        .target(
            name: "TMDB_TVShowDetail",
            dependencies: [
                "CoreFeatures",
                "TMDB_Shared_Backend",
                "TMDB_Shared_UI",
                "Shared_UI_Support",
            ]
        ),
        .target(
            name: "TMDB_Person",
            dependencies: [
                "TMDB_Shared_Backend",
                "TMDB_Shared_UI",
                "Shared_UI_Support",
                "CoreFeatures",
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        // Movie list
        .target(
            name: "TMDB_Feed",
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
            name: "TMDB_Feed_Tests",
            dependencies: ["TMDB_Feed", "TMDB_Shared_Backend", "ViewInspector", "Tests_Shared_Helpers"],
            resources: [.process("Resources")]
        ),
        // Discover feed - clean architecture
        .target(
            name: "TMDB_Discover",
            dependencies: [
                "Swinject",
                "TMDB_Shared_UI",
                "TMDB_Shared_Backend",
                "CoreFeatures",
                "Shared_UI_Support",
                .product(name: "SnapKit", package: "SnapKit"),

            ],
            swiftSettings: [.define("DEBUG", .when(configuration: .debug))]
        ),
        .testTarget(
            name: "TMDB_Discover_Tests",
            dependencies: ["TMDB_Discover", "Tests_Shared_Helpers", "ViewInspector"]
        ),

        .target(
            name: "TMDB_Profile",
            dependencies: [
                "TMDB_Shared_Backend",
                "Swinject",
                "Kingfisher",
                "Shared_UI_Support",
                "TMDB_Shared_UI",
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
            ]
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
            name: "Shared_UI_Support",
            dependencies: [
                .product(name: "SnapKit", package: "SnapKit"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ],
            resources: [.process("Resources")]
        ),
        .target(
            name: "CoreFeatures"
        ),

        .target(
            name: "PhotoListViewer",
            dependencies: [
                "TMDB_Shared_UI",
                "TMDB_Shared_Backend",
            ]
        ),

        // MARK: Third Party

        .target(
            name: "third_party",
            dependencies: swiftfinTargetDependency
        ),

        // MARK: Integration Tests

        .target(
            name: "Integration_test",
            dependencies: [
                "everythingclient",
                "TMDB",
                "Pokedex",
                "TMDB_Feed",
                "TMDB_Discover",
                "TMDB_Profile",
                "TMDB_MovieDetail",
                "TMDB_TVShowDetail",
                "TMDB_Person",
                "PhotoListViewer",
                "third_party",
                "Pokedex_Pokelist",
                "Pokedex_Detail",
                "Pokedex_Shared_Backend",
                "TMDB_Shared_Backend",
                "TMDB_Shared_UI",
                "Shared_UI_Support",
                "CoreFeatures",
                "Swinject",
            ]
        ),
    ]
)
for target in package.targets {
  target.swiftSettings = target.swiftSettings ?? []
  target.swiftSettings?.append(
    .enableExperimentalFeature("StrictConcurrency")
  )

  target.linkerSettings = target.linkerSettings ?? []
  target.linkerSettings?.append(
    .unsafeFlags([
      "-Xlinker", "-ObjC",
    ])
  )
}
