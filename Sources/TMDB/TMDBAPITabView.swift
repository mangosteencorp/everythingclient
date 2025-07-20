import CoreFeatures
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
    case floating
    case page
}

@available(iOS 16, *)
public enum NavigationWrapStyle: Int, CaseIterable {
    case navigationView
    case plain

    func next() -> NavigationWrapStyle {
        let nextRawValue = (rawValue + 1) % NavigationWrapStyle.allCases.count
        return NavigationWrapStyle(rawValue: nextRawValue)!
    }

    var displayName: String {
        switch self {
        case .navigationView:
            return "Navigation View"
        case .plain:
            return "Plain"
        }
    }
}

@available(iOS 16, *)
public enum TabNavCombination: CaseIterable {
    case normalTabPlainNav
    case normalTabNavigationViewNav
    case floatingTabPlainNav
    case floatingTabNavigationViewNav

    var tabStyle: TabStyle {
        switch self {
        case .normalTabPlainNav, .normalTabNavigationViewNav:
            return .normal
        case .floatingTabPlainNav, .floatingTabNavigationViewNav:
            return .floating
        }
    }

    var navigationStyle: NavigationWrapStyle {
        switch self {
        case .normalTabPlainNav, .floatingTabPlainNav:
            return .plain
        case .normalTabNavigationViewNav, .floatingTabNavigationViewNav:
            return .navigationView
        }
    }

    var displayName: String {
        switch self {
        case .normalTabPlainNav:
            return "Normal Tab + Plain Nav"
        case .normalTabNavigationViewNav:
            return "Normal Tab + Navigation View"
        case .floatingTabPlainNav:
            return "Floating Tab + Plain Nav"
        case .floatingTabNavigationViewNav:
            return "Floating Tab + Navigation View"
        }
    }

    var isValid: Bool {
        // NavigationView is only valid on iPad for split view purposes
        if navigationStyle == .navigationView && UIDevice.current.userInterfaceIdiom != .pad {
            return false
        }
        return true
    }

    static var validCases: [TabNavCombination] {
        return allCases.filter { $0.isValid }
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

    public init(tmdbKey: String,
                tabStyle: TabStyle? = nil,
                navigationInterceptor: TMDBNavigationInterceptor? = nil,
                analyticsTracker: AnalyticsTracker? = nil) {
        self.tmdbKey = tmdbKey
        let defaultTabStyle = tabStyle ?? (UIDevice.current.userInterfaceIdiom == .pad ? .normal : .floating)
        let defaultCombination: TabNavCombination = defaultTabStyle == .normal ? .normalTabPlainNav : .floatingTabPlainNav
        tabNavCombination = defaultCombination
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
        Group {
            switch tabNavCombination.tabStyle {
            case .normal:
                normalTabView
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
        .withTMDBNavigationDestinations(container: container)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                SwitchTabNavDesignToolbarItem(tabNavCombination: $tabNavCombination)
            }
        }

        movieFeedContent
            .withTabNavCombination(tabNavCombination, coordinator: coordinator, tabRoute: .movieFeed)
    }

    @ViewBuilder
    private func buildTVShowFeedPage() -> some View {
        let tvShowContent = TMDB_Discover.TVShowListPage(
            container: container,
            apiKey: tmdbKey,
            type: .onTheAir
        ) { tvShowId in
            TMDBRoute.tvShowDetail(tvShowId)
        }
        .withTMDBNavigationDestinations(container: container)

        tvShowContent
            .withTabNavCombination(tabNavCombination, coordinator: coordinator, tabRoute: .tvShowFeed)
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
            buildMovieFeedPage()
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
            buildMovieFeedPage()
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
                buildMovieFeedPage()
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
    }
}

// MARK: - ViewModifiers

@available(iOS 16, *)
private struct TabNavCombinationModifier: ViewModifier {
    let tabNavCombination: TabNavCombination
    let coordinator: Coordinator
    let tabRoute: TabRoute

    func body(content: Content) -> some View {
        switch tabNavCombination {
        case .normalTabPlainNav, .floatingTabPlainNav:
            NavigationStack(path: coordinator.path(for: tabRoute)) {
                content
            }
        case .normalTabNavigationViewNav, .floatingTabNavigationViewNav:
            NavigationStack(path: coordinator.path(for: tabRoute)) {
                NavigationView {
                    content
                }
            }
        }
    }
}

@available(iOS 16, *)
private extension View {
    func withTabNavCombination(_ combination: TabNavCombination, coordinator: Coordinator, tabRoute: TabRoute) -> some View {
        modifier(TabNavCombinationModifier(tabNavCombination: combination, coordinator: coordinator, tabRoute: tabRoute))
    }
}
