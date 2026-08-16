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

@available(iOS 16, *)
public enum TabStyle: CaseIterable {
    case normal
    case sidebar
    case floating
    case page
}

@available(iOS 16, *)
public enum NavigationWrapStyle: Int, CaseIterable {
    case navigationSplit
    case plain

    func next() -> NavigationWrapStyle {
        let nextRawValue = (rawValue + 1) % NavigationWrapStyle.allCases.count
        return NavigationWrapStyle(rawValue: nextRawValue)!
    }

    var displayName: String {
        switch self {
        case .navigationSplit:
            return "Split View"
        case .plain:
            return "Plain"
        }
    }
}

@available(iOS 16, *)
public enum TabNavCombination: CaseIterable {
    case normalTabPlainNav
    case normalTabNavigationSplitNav
    case sidebarTabPlainNav
    case sidebarTabNavigationSplitNav
    case floatingTabPlainNav
    case floatingTabNavigationSplitNav

    var tabStyle: TabStyle {
        switch self {
        case .normalTabPlainNav, .normalTabNavigationSplitNav:
            return .normal
        case .sidebarTabPlainNav, .sidebarTabNavigationSplitNav:
            return .sidebar
        case .floatingTabPlainNav, .floatingTabNavigationSplitNav:
            return .floating
        }
    }

    var navigationStyle: NavigationWrapStyle {
        switch self {
        case .normalTabPlainNav, .sidebarTabPlainNav, .floatingTabPlainNav:
            return .plain
        case .normalTabNavigationSplitNav, .sidebarTabNavigationSplitNav, .floatingTabNavigationSplitNav:
            return .navigationSplit
        }
    }

    var displayName: String {
        switch self {
        case .normalTabPlainNav:
            return "Normal Tab + Plain Nav"
        case .normalTabNavigationSplitNav:
            return "Normal Tab + Split View"
        case .sidebarTabPlainNav:
            return "Sidebar Tab + Plain Nav"
        case .sidebarTabNavigationSplitNav:
            return "Sidebar Tab + Split View"
        case .floatingTabPlainNav:
            return "Floating Tab + Plain Nav"
        case .floatingTabNavigationSplitNav:
            return "Floating Tab + Split View"
        }
    }

    var isValid: Bool {
        // Split navigation is intended for iPad two-column layout
        if navigationStyle == .navigationSplit && UIDevice.current.userInterfaceIdiom != .pad {
            return false
        }

        if tabStyle == .sidebar {
            if #available(iOS 27, *) {
                return true
            }

            return false
        }

        return true
    }

    static var validCases: [TabNavCombination] {
        allCases.filter(\.isValid)
    }
}

@available(iOS 16, *)
public struct TMDBAPITabView: View {
    @StateObject private var coordinator: Coordinator
    private let container: Container
    private let tmdbKey: String
    private let analyticsTracker: AnalyticsTracker?
    @State private(set) var tabNavCombination: TabNavCombination
    @State private var isShowingMovieDetail = false
    @State private var isShowingTVShowDetail = false
    @State private var selectedMovieId: Int?
    @State private var selectedTVShowId: Int?
    private let navigationInterceptor: TMDBNavigationInterceptor?

    private static var defaultTabStyle: TabStyle {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            return .floating
        }

        if #available(iOS 27, *) {
            return .sidebar
        }

        return .normal
    }

    public init(tmdbKey: String,
                tabStyle: TabStyle? = nil,
                navigationInterceptor: TMDBNavigationInterceptor? = nil,
                analyticsTracker: AnalyticsTracker? = nil) {
        self.tmdbKey = tmdbKey
        let defaultTabStyle = tabStyle ?? Self.defaultTabStyle
        let defaultCombination: TabNavCombination
        switch defaultTabStyle {
        case .normal, .page:
            defaultCombination = .normalTabPlainNav
        case .sidebar:
            defaultCombination = .sidebarTabPlainNav
        case .floating:
            defaultCombination = .floatingTabPlainNav
        }
        tabNavCombination = defaultCombination
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
            switch tabNavCombination.tabStyle {
            case .normal:
                normalTabView
            case .sidebar:
                sidebarTabView
            case .floating:
                floatingTabView
            case .page:
                pageTabView
            }
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
            ToolbarItem(placement: .topBarLeading) {
                SwitchTabNavDesignToolbarItem(tabNavCombination: $tabNavCombination)
            }
        }

        movieFeedContent
            .withTabNavCombination(
                tabNavCombination,
                coordinator: coordinator,
                tabRoute: .movieFeed,
                container: container
            )
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

    // MARK: - Tab Views

    @ViewBuilder
    private var systemTabView: some View {
        TabView(selection: $coordinator.selectedTab) {
            // Movie Feed Tab
            buildMovieFeedPage()
                .tabItem {
                Image(systemName: TabRoute.movieFeed.iconName)
                Text(TabRoute.movieFeed.title)
            }
            .tag(TabRoute.movieFeed)

            // Marketplace Tab
            NavigationStack(path: coordinator.path(for: .marketplace)) {
                buildMarketplacePage()
            }
            .tabItem {
                Image(systemName: TabRoute.marketplace.iconName)
                Text(TabRoute.marketplace.title)
            }
            .tag(TabRoute.marketplace)

            // Profile Tab
            NavigationStack(path: coordinator.path(for: .profile)) {
                buildProfilePage()
            }
            .tabItem {
                Image(systemName: TabRoute.profile.iconName)
                Text(TabRoute.profile.title)
            }
            .tag(TabRoute.profile)

            // Settings Tab
            NavigationStack(path: coordinator.path(for: .settings)) {
                buildSettingsPage()
            }
            .tabItem {
                Image(systemName: TabRoute.settings.iconName)
                Text(TabRoute.settings.title)
            }
            .tag(TabRoute.settings)
        }
    }

    @ViewBuilder
    private var normalTabView: some View {
        systemTabView
        .environmentObject(coordinator)
    }

    @ViewBuilder
    private var sidebarTabView: some View {
        systemTabView
        .withDefaultSidebarTabBarPlacement()
        .environmentObject(coordinator)
    }

    @ViewBuilder
    private var pageTabView: some View {
        TabView(selection: $coordinator.selectedTab) {
            // Movie Feed Page
            buildMovieFeedPage()
            .tag(TabRoute.movieFeed)

            // Marketplace Page
            NavigationStack(path: coordinator.path(for: .marketplace)) {
                buildMarketplacePage()
            }
            .tag(TabRoute.marketplace)

            // Profile Page
            NavigationStack(path: coordinator.path(for: .profile)) {
                buildProfilePage()
            }
            .tag(TabRoute.profile)

            // Settings Page
            NavigationStack(path: coordinator.path(for: .settings)) {
                buildSettingsPage()
            }
            .tag(TabRoute.settings)
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
                buildMovieFeedPage()
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

            // Floating tab bar at the bottom
            FloatingTabBar(selection: $coordinator.selectedTab, isHidden: Binding(
                get: { coordinator.tabBarHiddenStates[coordinator.selectedTab] ?? false },
                set: { _ in }
            ), items: tabItems)
        }
        .environmentObject(coordinator)
    }
}

// MARK: - Toolbar Items

@available(iOS 16, *)
private struct SwitchTabNavDesignToolbarItem: View {
    @Binding var tabNavCombination: TabNavCombination

    var body: some View {
        Menu {
            ForEach(TabNavCombination.validCases, id: \.self) { combination in
                Button(action: {
                    tabNavCombination = combination
                }) {
                    HStack {
                        Text(combination.displayName)
                        if tabNavCombination == combination {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "figure.jumprope")
        }
        .adaptiveContainerCornerOffset(.horizontal, sizeToFit: true)
    }
}

// MARK: - ViewModifiers

@available(iOS 16, *)
private struct TabNavCombinationModifier: ViewModifier {
    let tabNavCombination: TabNavCombination
    let coordinator: Coordinator
    let tabRoute: TabRoute
    let container: Container

    func body(content: Content) -> some View {
        switch tabNavCombination {
        case .normalTabPlainNav, .sidebarTabPlainNav, .floatingTabPlainNav:
            NavigationStack(path: coordinator.path(for: tabRoute)) {
                content
                    .withTMDBNavigationDestinations(container: container)
            }
        case .normalTabNavigationSplitNav, .sidebarTabNavigationSplitNav, .floatingTabNavigationSplitNav:
            // Why the old setup failed on iPad:
            // 1) `NavigationView { singleChild }` is always stack-style (one column).
            // 2) Nesting that inside `NavigationStack` collapsed any column layout.
            // NavigationSplitView provides an explicit sidebar + detail column pair;
            // destinations on the sidebar content appear in the detail column.
            NavigationSplitView {
                content
                    .withTMDBNavigationDestinations(container: container)
            } detail: {
                FeedSplitDetailPlaceholder()
            }
            .navigationSplitViewStyle(.balanced)
        }
    }
}

@available(iOS 16, *)
private struct FeedSplitDetailPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "film")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(L10nFeedSelect.title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(L10nFeedSelect.prompt)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("feed.split.detail.placeholder")
    }
}

/// Local strings for the split-detail placeholder (TMDB module may not import TMDB_Feed L10n).
private enum L10nFeedSelect {
    static let title = "Select a title"
    static let prompt = "Choose a movie or TV show to see details."
}

@available(iOS 16, *)
private extension View {
    func withTabNavCombination(
        _ combination: TabNavCombination,
        coordinator: Coordinator,
        tabRoute: TabRoute,
        container: Container
    ) -> some View {
        modifier(TabNavCombinationModifier(
            tabNavCombination: combination,
            coordinator: coordinator,
            tabRoute: tabRoute,
            container: container
        ))
    }

    @ViewBuilder
    func withDefaultSidebarTabBarPlacement() -> some View {
        #if compiler(>=6.4)
        if #available(iOS 27, *) {
            defaultTabBarPlacement(.sidebar)
        } else {
            self
        }
        #else
        self
        #endif
    }
}
