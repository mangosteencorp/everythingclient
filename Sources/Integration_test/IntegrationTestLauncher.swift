import CoreFeatures
import everythingclient
import Pokedex
import Shared_UI_Support
import SwiftUI
import TMDB
import TMDB_Feed
import TMDB_MovieDetail
import TMDB_Person
import TMDB_Shared_Backend
import TMDB_TVShowDetail
// UIKit-backed modules, iOS only; see `Package.swift`.
#if os(iOS)
import Pokedex_Detail
import Pokedex_Pokelist
import TMDB_Discover
import TMDB_Profile
#endif
#if DEBUG
@available(iOS 16, *)
public struct IntegrationTestLauncher {
    public enum DemoTest: String, CaseIterable {
        case appRoot = "AppRoot"
        case tmdbTabsNormal = "TMDBTabsNormal"
        case tmdbTabsPage = "TMDBTabsPage"
        case tmdbTabsEmbedded = "TMDBTabsEmbedded"
        case tmdbFeed = "TMDBFeed"
        case tmdbDiscover = "TMDBDiscover"
        case tmdbMovieDetail = "TMDBMovieDetail"
        case tmdbTVShowDetail = "TMDBTVShowDetail"
        case tmdbSettings = "TMDBSettings"
        case tmdbPersonDetail = "TMDBPersonDetail"
        case pokedexList = "PokedexList"
        case pokedexDetail = "PokedexDetail"
        case pokedexTab = "PokedexTab"
        case themeSwitcher = "ThemeSwitcher"
        case demoLauncher = "DemoLauncher"

        public var displayName: String {
            switch self {
            case .appRoot: return "App Root"
            case .tmdbTabsNormal: return "TMDB Tabs — Normal"
            case .tmdbTabsPage: return "TMDB Tabs — Page"
            case .tmdbTabsEmbedded: return "TMDB Tabs — Embedded"
            case .tmdbFeed: return "TMDB Feed"
            case .tmdbDiscover: return "TMDB Discover"
            case .tmdbMovieDetail: return "TMDB Movie Detail"
            case .tmdbTVShowDetail: return "TMDB TV Show Detail"
            case .tmdbSettings: return "TMDB Settings"
            case .tmdbPersonDetail: return "TMDB Person Detail"
            case .pokedexList: return "Pokedex List"
            case .pokedexDetail: return "Pokedex Detail"
            case .pokedexTab: return "Pokedex Tab"
            case .themeSwitcher: return "Theme Switcher"
            case .demoLauncher: return "Demo Launcher"
            }
        }

        public var accessibilityIdentifier: String {
            "integration.preview.\(rawValue)"
        }
    }

    @ViewBuilder
    public static func launch(named testName: String) -> some View {
        if let demoTest = DemoTest(rawValue: testName) {
            launch(demoTest)
        } else {
            IntegrationTestErrorView(message: "Unknown test: \(testName)")
                .accessibilityIdentifier("integration.preview.unknown")
        }
    }

    @ViewBuilder
    public static func launch(_ demoTest: DemoTest) -> some View {
        previewContent(for: demoTest)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(demoTest.accessibilityIdentifier)
    }

    public static func getAvailableTests() -> [DemoTest] {
        #if os(iOS)
        DemoTest.allCases
        #else
        DemoTest.allCases.filter { !uiKitOnlyTests.contains($0) }
        #endif
    }

    /// Demos backed by UIKit modules, which ship on iOS only; see `Package.swift`.
    private static let uiKitOnlyTests: Set<DemoTest> = [
        .tmdbDiscover, .pokedexList, .pokedexDetail,
    ]

    #if !os(iOS)
    private static var unavailableOnThisPlatform: some View {
        IntegrationTestErrorView(message: "This demo is backed by a UIKit module and is iOS-only.")
    }
    #endif

    @ViewBuilder
    // This is the exhaustive runtime equivalent of the app's top-level preview catalog.
    // swiftlint:disable:next cyclomatic_complexity
    private static func previewContent(for demoTest: DemoTest) -> some View {
        switch demoTest {
        case .appRoot:
            RootContentView(TMDBApiKey: debugTMDBAPIKey, isAppStoreOrTestFlight: false)
        case .tmdbTabsNormal:
            TMDBAPITabView(tmdbKey: debugTMDBAPIKey, tabStyle: .normal)
        case .tmdbTabsPage:
            TMDBAPITabView(tmdbKey: debugTMDBAPIKey, tabStyle: .page)
        case .tmdbTabsEmbedded:
            TabView {
                TMDBAPITabView(tmdbKey: debugTMDBAPIKey)
                    .tabItem {
                        Label("TMDB", systemImage: "film")
                    }
            }
        case .tmdbFeed:
            TMDBFeedDemoView()
        case .tmdbDiscover:
            #if os(iOS)
            TMDBDiscoverDemoView()
            #else
            unavailableOnThisPlatform
            #endif
        case .tmdbMovieDetail:
            TMDBMovieDetailDemoView()
        case .tmdbTVShowDetail:
            TMDBTVShowDetailDemoView()
        case .tmdbSettings:
            TMDBSettingsDemoView()
        case .tmdbPersonDetail:
            TMDBPersonDetailDemoView()
        case .pokedexList:
            #if os(iOS)
            PokedexListDemoView()
            #else
            unavailableOnThisPlatform
            #endif
        case .pokedexDetail:
            #if os(iOS)
            PokedexDetailDemoView()
            #else
            unavailableOnThisPlatform
            #endif
        case .pokedexTab:
            PokedexTabView()
        case .themeSwitcher:
            ThemeSwitcherDemoView()
        case .demoLauncher:
            DemoLauncherView()
        }
    }
}

struct IntegrationTestErrorView: View {
    let message: String

    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text("Integration Test Error")
                .font(.headline)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
#endif
