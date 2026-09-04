import CoreFeatures
import Shared_UI_Support
import SwiftUI
import Swinject
import TMDB_Discover
import TMDB_Feed
import TMDB_MovieDetail
import TMDB_Profile
import TMDB_Shared_Backend
import TMDB_Shared_UI

/// Legacy seed for the shell design, kept so existing call sites keep compiling.
/// The live value lives in `DesignCoordinator` as `AppShellDesign`.
@available(iOS 16, *)
public enum TabStyle: CaseIterable {
    case normal
    case sidebar
    case floating
    case page

    var shellDesign: AppShellDesign {
        switch self {
        case .normal: return .bottomTabBar
        case .sidebar: return .sidebarTabBar
        case .floating: return .floatingTabBar
        case .page: return .pagedTabs
        }
    }
}

@available(iOS 16, *)
public struct TMDBAPITabView: View {
    @StateObject private var coordinator: Coordinator
    private let container: Container
    private let tmdbKey: String
    private let analyticsTracker: AnalyticsTracker?
    private let seedShellDesign: AppShellDesign?
    private let navigationInterceptor: TMDBNavigationInterceptor?

    @DesignStyle private var shellDesign: AppShellDesign
    @DesignStyle private var navigationDesign: AppNavigationDesign
    @State private var didApplySeed = false

    public init(tmdbKey: String,
                tabStyle: TabStyle? = nil,
                navigationInterceptor: TMDBNavigationInterceptor? = nil,
                analyticsTracker: AnalyticsTracker? = nil) {
        self.tmdbKey = tmdbKey
        seedShellDesign = tabStyle?.shellDesign
        self.navigationInterceptor = navigationInterceptor
        self.analyticsTracker = analyticsTracker
        let container = Container()
        TMDB_Shared_Backend.configure(
            container: container,
            apiKey: tmdbKey,
            urlCacheOptions: .enabled
        )
        if let interceptor = self.navigationInterceptor {
            container.register(TMDBNavigationInterceptor.self) { _ in interceptor }.inObjectScope(.container)
        }

        if let tracker = analyticsTracker {
            container.register(AnalyticsTracker.self) { _ in tracker }.inObjectScope(.container)
        }

        self.container = container

        let tabList: [TabRoute] = [.movieFeed, .marketplace, .profile, .settings]
        _coordinator = StateObject(wrappedValue: Coordinator(tabList: tabList))
    }

    public var body: some View {
        Group {
            switch shellDesign {
            case .bottomTabBar:
                SystemTabShell(coordinator: coordinator, usesSidebarPlacement: false, page: page(for:))
            case .sidebarTabBar:
                SystemTabShell(coordinator: coordinator, usesSidebarPlacement: true, page: page(for:))
            case .floatingTabBar:
                FloatingTabShell(coordinator: coordinator, page: page(for:))
            case .pagedTabs:
                PagedTabShell(coordinator: coordinator, page: page(for:))
            }
        }
        .environmentObject(coordinator)
        // Above every NavigationStack below: pushed pages inherit their stack's environment, so a
        // namespace published inside a stack never reaches them.
        .zoomTransitionNamespaceRoot()
        .onAppear {
            // Applied here rather than in `init` so the store is never mutated while the parent
            // view's body is being evaluated.
            guard !didApplySeed else { return }
            didApplySeed = true
            if let seedShellDesign {
                $shellDesign.wrappedValue = seedShellDesign
            }
        }
    }

    // MARK: - Pages

    /// One fully navigation-wrapped page per top-level tab. Shells only decide the chrome
    /// around this, never its content.
    @ViewBuilder
    private func page(for tab: TabRoute) -> some View {
        switch tab {
        case .movieFeed:
            buildMovieFeedPage()
                .withAppNavigationDesign(
                    navigationDesign,
                    coordinator: coordinator,
                    tabRoute: .movieFeed,
                    container: container
                )
        case .marketplace:
            NavigationStack(path: coordinator.path(for: .marketplace)) {
                buildMarketplacePage()
            }
        case .profile:
            NavigationStack(path: coordinator.path(for: .profile)) {
                buildProfilePage()
            }
        case .settings:
            NavigationStack(path: coordinator.path(for: .settings)) {
                buildSettingsPage()
            }
        }
    }

    // MARK: - Builders

    @ViewBuilder
    private func buildMovieFeedPage() -> some View {
        MovieFeedListPage(
            apiService: container.resolve(TMDBAPIService.self)!,
            analyticsTracker: analyticsTracker
        ) { movie in
            TMDBRoute.movieDetail(MovieRouteModel(
                id: movie.id,
                title: movie.title,
                overview: movie.overview,
                posterPath: movie.posterPath,
                backdropPath: movie.backdropPath,
                voteAverage: movie.voteAverage ?? 0.0,
                voteCount: movie.voteCount ?? 0,
                releaseDate: movie.releaseDate,
                popularity: movie.popularity,
                originalTitle: movie.originalTitle
            ))
        } tvShowDetailRouteBuilder: { tvShow in
            TMDBRoute.tvShowDetail(tvShow.id)
        }
        .toolbar {
            DesignShuffleToolbarItem(placement: .topBarLeading)
        }
    }

    @ViewBuilder
    private func buildMarketplacePage() -> some View {
        let marketplaceContent = TMDB_Discover.HomeDiscoverView(
            container: container,
            apiKey: tmdbKey
        ) { movieId in
            TMDBRoute.movieDetail(MovieRouteModel(id: movieId))
        } onItemTapped: {
            coordinator.navigate(to: .tvShowList(.onTheAir), in: .marketplace)
        } onGenreTapped: { genre in
            // Navigate to discover movies filtered by movie genre (using movie genre IDs)
            coordinator.navigate(to: .tvShowList(.discoverWithGenre(genre)), in: .marketplace)
        } onTVGenreTapped: { genre in
            // Navigate to discover TV shows filtered by TV genre (using TV genre IDs)
            coordinator.navigate(to: .tvShowList(.discoverWithTVGenre(genre)), in: .marketplace)
        } onCastTapped: { person in
            coordinator.navigate(to: .personDetail(person.id), in: .marketplace)
        } onTrendingItemTapped: { trendingItem in
            // Navigate based on the media type of the trending item
            switch trendingItem.mediaType {
            case .movie:
                coordinator.navigate(
                    to: .movieDetail(MovieRouteModel(
                        id: trendingItem.id,
                        title: trendingItem.title ?? "Unknown",
                        overview: trendingItem.overview ?? "",
                        posterPath: trendingItem.posterPath,
                        backdropPath: trendingItem.backdropPath,
                        voteAverage: Float(trendingItem.voteAverage ?? 0.0),
                        voteCount: 0,
                        releaseDate: nil,
                        popularity: Float(trendingItem.popularity),
                        originalTitle: trendingItem.title
                    )),
                    in: .marketplace
                )
            case .tv:
                coordinator.navigate(to: .tvShowDetail(trendingItem.id), in: .marketplace)
            case .person:
                coordinator.navigate(to: .personDetail(trendingItem.id), in: .marketplace)
            }
        }

        marketplaceContent
            .withTMDBNavigationDestinations(container: container)
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

    @ViewBuilder
    private func buildSettingsPage() -> some View {
        SettingsPageView()
    }
}
