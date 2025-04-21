import CoreFeatures
import SwiftUI
import Swinject
import TMDB_clean_MLS
import TMDB_Clean_Profile
import TMDB_MVVM_Detail
import TMDB_MVVM_MLS
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

        if let tracker = analyticsTracker {
            container.register(AnalyticsTracker.self) { _ in tracker }.inObjectScope(.container)
        }

        self.container = container

        let tabList: [TabRoute] = [.nowPlaying, .upcoming, .profile]
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
            case .nowPlaying:
                NavigationStack(path: coordinator.path(for: .nowPlaying)) {
                    DMSNowPlayingPage(apiService: container.resolve(TMDBAPIService.self)!, analyticsTracker: self.analyticsTracker) { movie in
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
            case .upcoming:
                NavigationStack(path: coordinator.path(for: .upcoming)) {
                    TMDB_clean_MLS.MovieListPage(
                        container: container,
                        apiKey: tmdbKey,
                        type: .upcoming
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
            FloatingTabBar(selection: $coordinator.selectedTab, isHidden: .constant(false), items: tabItems)
        }
        .environmentObject(coordinator)
    }
}

struct FloatingTabItem<Selection: Hashable> {
    let tag: Selection
    let icon: Image
    let title: String
}

// Define the floating tab bar view
struct FloatingTabBar<Selection: Hashable>: View {
    @Binding var selection: Selection
    @Binding var isHidden: Bool
    let items: [FloatingTabItem<Selection>]

    var body: some View {
        if !isHidden {
            HStack {
                ForEach(items, id: \.tag) { item in
                    Button(action: {
                        selection = item.tag
                    }) {
                        HStack {
                            item.icon
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            Text(item.title)
                        }
                        .foregroundColor(item.tag == selection ? .blue : .gray)
                        .padding(.vertical, 8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(.horizontal)
        } else {
            EmptyView()
        }
    }
}
