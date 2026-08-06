import Combine
import CoreFeatures
import Foundation
import Shared_UI_Support
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

@available(iOS 16, *)
public struct MovieFeedListPage<Route: Hashable>: View {
    @StateObject var movieViewModel: MovieFeedViewModel
    @StateObject var tvShowViewModel: TVShowFeedViewModel
    @State private var selectedTab: FeedTab = .nowPlaying
    @State private var visibleTab: FeedTab = .nowPlaying
    @State private var useFancyDesign: Bool = true
    let detailRouteBuilder: (Movie) -> Route
    let tvShowDetailRouteBuilder: (TVShow) -> Route

    public init(
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        detailRouteBuilder: @escaping (Movie) -> Route,
        tvShowDetailRouteBuilder: @escaping (TVShow) -> Route
    ) {
        _movieViewModel = StateObject(wrappedValue: MovieFeedViewModel(
            apiService: apiService,
            additionalParams: additionalParams,
            analyticsTracker: analyticsTracker
        ))
        _tvShowViewModel = StateObject(wrappedValue: TVShowFeedViewModel(
            apiService: apiService,
            additionalParams: additionalParams,
            analyticsTracker: analyticsTracker
        ))
        self.detailRouteBuilder = detailRouteBuilder
        self.tvShowDetailRouteBuilder = tvShowDetailRouteBuilder
    }

#if DEBUG
    init(
        movieViewModel: MovieFeedViewModel,
        tvShowViewModel: TVShowFeedViewModel,
        detailRouteBuilder: @escaping (Movie) -> Route,
        tvShowDetailRouteBuilder: @escaping (TVShow) -> Route
    ) {
        _movieViewModel = StateObject(wrappedValue: movieViewModel)
        _tvShowViewModel = StateObject(wrappedValue: tvShowViewModel)
        self.detailRouteBuilder = detailRouteBuilder
        self.tvShowDetailRouteBuilder = tvShowDetailRouteBuilder
    }
#endif

    public var body: some View {
        Group {
            // There are more tabs than the tab bar can show, so iOS moves the overflow
            // into its "More" list. The legacy `.tabItem` bridge renders those overflow
            // tabs into a detached controller that never redraws, so they stay frozen on
            // whatever was on screen when the More list was built (an empty feed showing
            // "No Results Found"). The iOS 18 `Tab` API keeps them live.
            if #available(iOS 18, *) {
                TabView(selection: $selectedTab) {
                    ForEach(FeedTab.allCases) { tab in
                        Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                            tabRoot(for: tab)
                        }
                    }
                }
            } else {
                TabView(selection: $selectedTab) {
                    ForEach(FeedTab.allCases) { tab in
                        tabRoot(for: tab)
                            .tabItem {
                                Label(tab.title, systemImage: tab.systemImage)
                            }
                            .tag(tab)
                    }
                }
            }
        }
        .accessibilityIdentifier("movies_list")
        .navigationTitle(visibleTab.title)
        .navigationBarTitleDisplayMode(.inline)
        // Tabs moved into iOS's More menu can be created without appearing first.
        .onAppear {
            loadInitialFeeds()
        }
        .onChange(of: selectedTab) { tab in
            visibleTab = tab
            loadFeed(for: tab)
        }
    }

    private func loadInitialFeeds() {
        for feedType in TVShowFeedType.allCases {
            if tvShowViewModel.shows(for: feedType).isEmpty,
               !tvShowViewModel.isLoading(for: feedType) {
                tvShowViewModel.loadFeed(feedType)
            }
        }

        loadFeed(for: selectedTab)
    }

    private func loadFeed(for tab: FeedTab) {
        if let feedType = tab.movieFeedType {
            if movieViewModel.movies(for: feedType).isEmpty,
               !movieViewModel.isLoading(for: feedType) {
                movieViewModel.loadFeed(feedType)
            }
        } else if let feedType = tab.tvShowFeedType {
            if tvShowViewModel.shows(for: feedType).isEmpty,
               !tvShowViewModel.isLoading(for: feedType) {
                tvShowViewModel.loadFeed(feedType)
            }
        }
    }

    private func tabRoot(for tab: FeedTab) -> some View {
        // iOS never updates the `selection` binding for tabs opened from the More list,
        // so the visible tab has to be tracked from the content itself to keep the
        // navigation title in sync.
        tabContent(for: tab)
            .onAppear { visibleTab = tab }
    }

    @ViewBuilder
    private func tabContent(for tab: FeedTab) -> some View {
        switch tab {
        case .nowPlaying, .popular, .topRated, .upcoming:
            if let feedType = tab.movieFeedType {
                MovieFeedTabContent(
                    viewModel: movieViewModel,
                    feedType: feedType,
                    detailRouteBuilder: detailRouteBuilder,
                    useFancyDesign: $useFancyDesign
                )
            }
        case .onTheAir, .airingToday:
            if let feedType = tab.tvShowFeedType {
                TVShowFeedTabContent(
                    viewModel: tvShowViewModel,
                    feedType: feedType,
                    detailRouteBuilder: tvShowDetailRouteBuilder,
                    useFancyDesign: $useFancyDesign
                )
            }
        case .search:
            FeedSearchTabContent(
                movieViewModel: movieViewModel,
                tvShowViewModel: tvShowViewModel,
                detailRouteBuilder: detailRouteBuilder,
                tvShowDetailRouteBuilder: tvShowDetailRouteBuilder,
                useFancyDesign: $useFancyDesign
            )
        }
    }
}

extension TVShow {
    func toMovieRowEntity() -> MovieRowEntity {
        MovieRowEntity(
            id: id,
            posterPath: poster_path,
            title: name,
            voteAverage: Double(vote_average),
            releaseDate: nil,
            overview: overview
        )
    }
}

#if DEBUG
// swiftlint:disable all
@available(iOS 16, *)
#Preview {
    MovieFeedListPage(
        apiService: TMDBAPIService(apiKey: debugTMDBAPIKey),
        detailRouteBuilder: { _ in 1 },
        tvShowDetailRouteBuilder: { _ in 2 }
    )
}

@available(iOS 16, *)
struct MovieFeedListPage_Previews: PreviewProvider {
    static var previews: some View {
        let movieViewModel = MovieFeedViewModel(apiService: TMDBAPIService(apiKey: debugTMDBAPIKey))
        let tvShowViewModel = TVShowFeedViewModel(apiService: TMDBAPIService(apiKey: debugTMDBAPIKey))

        return NavigationStack {
            MovieFeedListPage(
                movieViewModel: movieViewModel,
                tvShowViewModel: tvShowViewModel,
                detailRouteBuilder: { _ in 1 },
                tvShowDetailRouteBuilder: { _ in 2 }
            )
        }
    }
}
// swiftlint:enable all
#endif
