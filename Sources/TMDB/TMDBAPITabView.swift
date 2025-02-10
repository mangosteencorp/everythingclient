import TMDB_MVVM_MLS
import TMDB_MVVM_Detail
import TMDB_clean_MLS
import TMDB_Clean_Profile
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI
import Swinject
@available(iOS 16,*)
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
        //.tabViewStyle(PageTabViewStyle())
        .environmentObject(coordinator)
    }
    
    @ViewBuilder
    private func navigationStackForTab(_ tab: TabRoute) -> some View {
        NavigationStack(path: coordinator.path(for: tab)) {
            switch tab {
            case .nowPlaying:
                DMSNowPlayingPage(apiKey: tmdbKey)
                    .navigationDestination(for: MovieDetailRoute.self) { route in
                        MovieDetailPage(movieRoute: route.movie, apiKey: tmdbKey)
                    }
            case .upcoming:
                TMDB_clean_MLS.MovieListPage(container: container, apiKey: tmdbKey, type: .upcoming)
                    .navigationDestination(for: MovieDetailRoute.self) { route in
                        MovieDetailPage(movieRoute: route.movie, apiKey: tmdbKey)
                    }
            case .profile:
                ProfilePageVCView(container: container,
                                  onNavigateToMovie: { movieId in
                    selectedMovieId = movieId
                    isShowingMovieDetail = true
                },
                                  onNavigateToTVShow: { tvShowId in
                    selectedTVShowId = tvShowId
                    isShowingTVShowDetail = true
                }
                )
                .navigationDestination(isPresented: $isShowingMovieDetail) {
                    if let movieId = selectedMovieId {
                        MovieDetailPage(movieId: movieId, apiKey: tmdbKey)
                    }
                }
                .navigationDestination(isPresented: $isShowingTVShowDetail) {
                    if let tvShowId = selectedTVShowId {
                        Text("TV Show Detail \(tvShowId)") // Replace with actual TV show detail view
                    }
                }
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
#if DEBUG
@available(iOS 16,*)
#Preview {
    TMDBAPITabView(tmdbKey: "")
}
@available(iOS 16,*)
#Preview("Tab contain TMDBAPITabView") {
    TabView {
        TMDBAPITabView(tmdbKey: "YOUR_API_KEY")
            .tabItem {
                Label("TMDB", systemImage: "film")
            }
    }
}
#endif
