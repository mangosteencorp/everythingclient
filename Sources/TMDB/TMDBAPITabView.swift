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

    @State private var isShowingMovieDetail = false
    @State private var isShowingTVShowDetail = false
    @State private var selectedMovieId: Int?
    @State private var selectedTVShowId: Int?

    public init(tmdbKey: String) {
        self.tmdbKey = tmdbKey
        let container = Container()
        TMDB_Shared_Backend.configure(container: container, apiKey: tmdbKey)
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
                DMSNowPlayingPage(apiKey: tmdbKey) { movie in
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
                ) { movieId in
                    TMDBRoute.movieDetail(MovieRouteModel(id: movieId))
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

    private var previousButton: some View {
        Button(action: {
            if coordinator.currentIndex > 0 {
                coordinator.switchTab(to: coordinator.currentIndex - 1)
            }
        }) {
            Text("<")
        }
        .disabled(coordinator.currentIndex == 0)
    }

    private var nextButton: some View {
        Button(action: {
            if coordinator.currentIndex < coordinator.tabList.count - 1 {
                coordinator.switchTab(to: coordinator.currentIndex + 1)
            }
        }) {
            Text(">")
        }
        .disabled(coordinator.currentIndex == coordinator.tabList.count - 1)
    }
}
