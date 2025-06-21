import CoreFeatures
import SwiftUI
import Swinject
import TMDB_clean_MLS
import TMDB_Clean_Profile
import TMDB_Movie_Feed
import TMDB_MVVM_Detail
import TMDB_Shared_Backend
import TMDB_Shared_UI

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

        // Register analytics tracker
        if let tracker = analyticsTracker {
            container.register(AnalyticsTracker.self) { _ in tracker }.inObjectScope(.container)
        }

        self.container = container

        let tabList: [TabRoute] = [.nowPlaying, .upcoming, .profile]
        _coordinator = StateObject(wrappedValue: Coordinator(tabList: tabList))
    }

    public var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            ForEach(coordinator.tabList, id: \.self) { tab in
                navigationStackForTab(tab)
                    .tabItem {
                        Image(systemName: tab.iconName)
                    }
                    .tag(tab)
            }
        }
        // .tabViewStyle(PageTabViewStyle())
        .environmentObject(coordinator)
    }

    @ViewBuilder
    private func navigationStackForTab(_ tab: TabRoute) -> some View {
        NavigationStack(path: coordinator.path(for: tab)) {
            switch tab {
            case .nowPlaying:
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

            case .upcoming:
                TMDB_clean_MLS.MovieListPage(
                    container: container,
                    apiKey: tmdbKey,
                    type: .upcoming
                ) { tvShowId in
                    TMDBRoute.tvShowDetail(tvShowId)
                }
                .withTMDBNavigationDestinations(container: container)

            case .profile:
                ProfilePageVCView(container: container) { movieId in
                    coordinator.navigate(to: .movieDetail(MovieRouteModel(id: movieId)), in: tab)
                } onNavigateToTVShow: { tvShowId in
                    coordinator.navigate(to: .tvShowDetail(tvShowId), in: tab)
                }
                .withTMDBNavigationDestinations(container: container)
            }
        }
    }
}
