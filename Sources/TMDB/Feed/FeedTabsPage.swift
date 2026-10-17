import CoreFeatures
import SwiftUI
import TMDB_Feed
import TMDB_Shared_Backend

/// Every feed behind one tab level. Each tab is a `FeedPage` with its own view model, so the
/// feeds never share loading state or pagination.
@available(iOS 16, *)
struct FeedTabsPage<Route: Hashable>: View {
    private let apiService: APIServiceProtocol
    private let additionalParams: AdditionalMovieListParams?
    private let analyticsTracker: AnalyticsTracker?
    private let detailRouteBuilder: (TMDB_Feed.Movie) -> Route
    private let tvShowDetailRouteBuilder: (TVShow) -> Route

    @State private var selectedTab: FeedKind = .nowPlaying
    @State private var visibleTab: FeedKind = .nowPlaying

    init(
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        detailRouteBuilder: @escaping (TMDB_Feed.Movie) -> Route,
        tvShowDetailRouteBuilder: @escaping (TVShow) -> Route
    ) {
        self.apiService = apiService
        self.additionalParams = additionalParams
        self.analyticsTracker = analyticsTracker
        self.detailRouteBuilder = detailRouteBuilder
        self.tvShowDetailRouteBuilder = tvShowDetailRouteBuilder
    }

    var body: some View {
        FeedTabContainer(
            tabs: FeedKind.allCases,
            selection: $selectedTab,
            visibleTab: $visibleTab
        ) { kind in
            FeedPage(
                kind: kind,
                apiService: apiService,
                additionalParams: additionalParams,
                analyticsTracker: analyticsTracker,
                detailRouteBuilder: detailRouteBuilder,
                tvShowDetailRouteBuilder: tvShowDetailRouteBuilder
            )
        }
        .accessibilityIdentifier("movies_list")
        // Set here too: a system `TabView` does not pass its tabs' titles up to this stack.
        .navigationTitle(visibleTab.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    TMDBPreviewCatalog.feedTabsPage.view
}
#endif
