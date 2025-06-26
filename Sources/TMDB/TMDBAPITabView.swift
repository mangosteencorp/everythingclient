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
public enum TabStyle {
    case normal
    case floating
    case page
}

@available(iOS 16, *)
public struct TMDBAPITabView: View {
    @StateObject private var coordinator: Coordinator
    private let container: Container
    private let tmdbKey: String
    private let analyticsTracker: AnalyticsTracker?
    private let tabStyle: TabStyle

    @State private var isShowingMovieDetail = false
    @State private var isShowingTVShowDetail = false
    @State private var selectedMovieId: Int?
    @State private var selectedTVShowId: Int?
    private let navigationInterceptor: TMDBNavigationInterceptor?

    public init(tmdbKey: String,
                tabStyle: TabStyle = .floating,
                navigationInterceptor: TMDBNavigationInterceptor? = nil,
                analyticsTracker: AnalyticsTracker? = nil) {
        self.tmdbKey = tmdbKey
        self.tabStyle = tabStyle
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
        switch tabStyle {
        case .normal:
            normalTabView
        case .floating:
            floatingTabView
        case .page:
            pageTabView
        }
    }

    // MARK: - Builders

    @ViewBuilder
    private func buildMovieFeedPage() -> some View {
        let movieFeedContent = MovieFeedListPage(
            apiService: container.resolve(TMDBAPIService.self)!,
            analyticsTracker: analyticsTracker
        ) { movie in
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

        if tabStyle == .page {
            NavigationView {
                movieFeedContent
            }
#if os(iOS)
            .navigationViewStyle(StackNavigationViewStyle())
#endif
        } else {
            movieFeedContent
        }
    }

    @ViewBuilder
    private func buildTVShowFeedPage() -> some View {
        let tvShowContent = TMDB_TVFeed.TVShowListPage(
            container: container,
            apiKey: tmdbKey,
            type: .onTheAir
        ) { tvShowId in
            TMDBRoute.tvShowDetail(tvShowId)
        }
        .withTMDBNavigationDestinations(container: container)

        if tabStyle == .page {
            NavigationView {
                tvShowContent
            }
#if os(iOS)
            .navigationViewStyle(StackNavigationViewStyle())
#endif
        } else {
            tvShowContent
        }
    }

    @ViewBuilder
    private func buildProfilePage() -> some View {
        ProfilePageVCView(container: container) { movieId in
            coordinator.navigate(to: .movieDetail(MovieRouteModel(id: movieId)), in: .profile)
        } onNavigateToTVShow: { tvShowId in
            coordinator.navigate(to: .tvShowDetail(tvShowId), in: .profile)
        }
        .withTMDBNavigationDestinations(container: container)
    }

    // MARK: - Tab Views

    @ViewBuilder
    private var normalTabView: some View {
        TabView(selection: $coordinator.selectedTab) {
            // Movie Feed Tab
            NavigationStack(path: coordinator.path(for: .movieFeed)) {
                buildMovieFeedPage()
            }
            .tabItem {
                Image(systemName: TabRoute.movieFeed.iconName)
                Text(TabRoute.movieFeed.title)
            }
            .tag(TabRoute.movieFeed)

            // TV Show Feed Tab
            NavigationStack(path: coordinator.path(for: .tvShowFeed)) {
                buildTVShowFeedPage()
            }
            .tabItem {
                Image(systemName: TabRoute.tvShowFeed.iconName)
                Text(TabRoute.tvShowFeed.title)
            }
            .tag(TabRoute.tvShowFeed)

            // Profile Tab
            NavigationStack(path: coordinator.path(for: .profile)) {
                buildProfilePage()
            }
            .tabItem {
                Image(systemName: TabRoute.profile.iconName)
                Text(TabRoute.profile.title)
            }
            .tag(TabRoute.profile)
        }
        .environmentObject(coordinator)
    }

    @ViewBuilder
    private var pageTabView: some View {
        TabView(selection: $coordinator.selectedTab) {
            // Movie Feed Page
            NavigationStack(path: coordinator.path(for: .movieFeed)) {
                buildMovieFeedPage()
            }
            .tag(TabRoute.movieFeed)

            // TV Show Feed Page
            NavigationStack(path: coordinator.path(for: .tvShowFeed)) {
                buildTVShowFeedPage()
            }
            .tag(TabRoute.tvShowFeed)

            // Profile Page
            NavigationStack(path: coordinator.path(for: .profile)) {
                buildProfilePage()
            }
            .tag(TabRoute.profile)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .environmentObject(coordinator)
    }

    @ViewBuilder
    private var floatingTabView: some View {
        // Create the tab items for the FloatingTabBar
        let tabItems = coordinator.tabList.map { tab in
            FloatingTabItem(tag: tab, icon: Image(systemName: tab.iconName), title: tab.title)
        }

        ZStack(alignment: .bottom) {
            // Content area: Switch between NavigationStacks based on selected tab
            switch coordinator.selectedTab {
            case .movieFeed:
                NavigationStack(path: coordinator.path(for: .movieFeed)) {
                    buildMovieFeedPage()
                }
            case .tvShowFeed:
                NavigationStack(path: coordinator.path(for: .tvShowFeed)) {
                    buildTVShowFeedPage()
                }
            case .profile:
                NavigationStack(path: coordinator.path(for: .profile)) {
                    buildProfilePage()
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
