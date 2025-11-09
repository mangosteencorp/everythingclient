import CoreFeatures
import Pokedex_Detail
import Pokedex_Pokelist
import Shared_UI_Support
import SwiftUI
import TMDB_Discover
import TMDB_Feed
import TMDB_MovieDetail
import TMDB_Profile
import TMDB_Shared_Backend
import TMDB_TVShowDetail
@available(iOS 16, *)
public struct IntegrationTestLauncher {
    public enum DemoTest: String, CaseIterable {
        case tmdbFeed = "TMDBFeed"
        case tmdbDiscover = "TMDBDiscover"
        case tmdbMovieDetail = "TMDBMovieDetail"
        case tmdbTVShowDetail = "TMDBTVShowDetail"
        case pokedexList = "PokedexList"
        case pokedexDetail = "PokedexDetail"
        case themeSwitcher = "ThemeSwitcher"

        var displayName: String {
            switch self {
            case .tmdbFeed: return "TMDB Feed"
            case .tmdbDiscover: return "TMDB Discover"
            case .tmdbMovieDetail: return "TMDB Movie Detail"
            case .tmdbTVShowDetail: return "TMDB TV Show Detail"
            case .pokedexList: return "Pokedex List"
            case .pokedexDetail: return "Pokedex Detail"
            case .themeSwitcher: return "Theme Switcher"
            }
        }
    }

    public static func launch(named testName: String) -> some View {
        guard let demoTest = DemoTest(rawValue: testName) else {
            return AnyView(IntegrationTestErrorView(message: "Unknown test: \(testName)"))
        }

        return AnyView(launch(demoTest))
    }

    public static func launch(_ demoTest: DemoTest) -> some View {
        switch demoTest {
        case .tmdbFeed:

            AnyView(TMDBFeedDemoView())

        case .tmdbDiscover:

            AnyView(TMDBDiscoverDemoView())

        case .tmdbMovieDetail:
            AnyView(TMDBMovieDetailDemoView())
        case .tmdbTVShowDetail:

            AnyView(TMDBTVShowDetailDemoView())

        case .pokedexList:
            AnyView(PokedexListDemoView())
        case .pokedexDetail:
            AnyView(PokedexDetailDemoView())
        case .themeSwitcher:
            AnyView(ThemeSwitcherDemoView())
        }
    }

    public static func getAvailableTests() -> [DemoTest] {
        return DemoTest.allCases
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
