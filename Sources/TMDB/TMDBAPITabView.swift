import CoreFeatures
import SwiftUI
import Swinject
import TMDB_Movie_Feed
import TMDB_MovieDetail
import TMDB_Profile
import TMDB_Shared_Backend
import TMDB_Shared_UI
import TMDB_TVFeed

@available(iOS 16, *)
public struct TMDBAPITabView: View {
    @StateObject private var coordinator: Coordinator
    private let container: Container
    private let tmdbKey: String
    private let analyticsTracker: AnalyticsTracker?

    @State private var isShowingMovieDetail = false
    @State private var isShowingTVShowDetail = false
    @State private var selectedMovieId: Int?
    @State private var selectedTVShowId: Int?
    private let navigationInterceptor: TMDBNavigationInterceptor?

    public init(tmdbKey: String,
                navigationInterceptor: TMDBNavigationInterceptor? = nil,
                analyticsTracker: AnalyticsTracker? = nil) {
        self.tmdbKey = tmdbKey
        self.navigationInterceptor = navigationInterceptor
        self.analyticsTracker = analyticsTracker

        let container = Container()
        TMDB_Shared_Backend.configure(container: container, apiKey: tmdbKey)
        if let interceptor = self.navigationInterceptor {
            container.register(TMDBNavigationInterceptor.self) { _ in interceptor }.inObjectScope(.container)
        }

        if let tracker = analyticsTracker {
            container.register(AnalyticsTracker.self) { _ in tracker }.inObjectScope(.container)
        }

        self.container = container

        let tabList: [TabRoute] = [.movieFeed, .tvShowFeed, .profile]
        _coordinator = StateObject(wrappedValue: Coordinator(tabList: tabList))
    }

    public var body: some View {
        // Create the tab items for the FloatingTabBar
        let tabItems = coordinator.tabList.map { tab in
            FloatingTabItem(tag: tab, icon: Image(systemName: tab.iconName), title: tab.title)
        }

        ZStack(alignment: .bottom) {
            // Content area: Switch between NavigationStacks based on selected tab
            switch coordinator.selectedTab {
            case .movieFeed:
                NavigationStack(path: coordinator.path(for: .movieFeed)) {
                    MovieFeedListPage(apiService: container.resolve(TMDBAPIService.self)!, analyticsTracker: self.analyticsTracker) { movie in
                        TMDBRoute.movieDetail(MovieRouteModel(
                            id: movie.id,
                            title: movie.title,
                            overview: movie.overview,
                            posterPath: movie.posterPath,
                            backdropPath: movie.backdropPath,
                            voteAverage: movie.voteAverage,
                            voteCount: movie.voteCount,
                            releaseDate: movie.releaseDate,
                            popularity: movie.popularity,
                            originalTitle: movie.originalTitle
                        ))
                    }
                    .withTMDBNavigationDestinations(container: container)
                }
            case .tvShowFeed:
                NavigationStack(path: coordinator.path(for: .tvShowFeed)) {
                    TMDB_TVFeed.MovieListPage(
                        container: container,
                        apiKey: tmdbKey,
                        type: .onTheAir
                    ) { tvShowId in
                        TMDBRoute.tvShowDetail(tvShowId)
                    }
                    .withTMDBNavigationDestinations(container: container)
                }
            case .profile:
                NavigationStack(path: coordinator.path(for: .profile)) {
                    ProfilePageVCView(container: container) { movieId in
                        coordinator.navigate(to: .movieDetail(MovieRouteModel(id: movieId)), in: .profile)
                    } onNavigateToTVShow: { tvShowId in
                        coordinator.navigate(to: .tvShowDetail(tvShowId), in: .profile)
                    }
                    .withTMDBNavigationDestinations(container: container)
                }
            }

            // Floating tab bar at the bottom
            FloatingTabBar(selection: $coordinator.selectedTab, isHidden: Binding(
                get: { coordinator.tabBarHiddenStates[coordinator.selectedTab] ?? false },
                set: { _ in }
            ), items: tabItems)
        }
        .environmentObject(coordinator)
    }
}
