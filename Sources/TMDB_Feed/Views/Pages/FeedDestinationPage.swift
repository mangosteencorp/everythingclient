import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

/// One feed category as a standalone page, for shells that promote the inner feed tabs to
/// their own destinations (a sidebar row, a pushed list row, a widget deep link).
///
/// Unlike `MovieFeedListPage`, which switches one pair of view models between categories, each
/// page owns its own view models. Several categories can therefore be alive at once — a
/// sidebar keeps the previous row loaded — without sharing one `state`/`currentPage` and
/// breaking each other's pagination.
@available(iOS 16, *)
public struct FeedDestinationPage<Route: Hashable>: View {
    @StateObject private var movieViewModel: MovieFeedViewModel
    @StateObject private var tvShowViewModel: TVShowFeedViewModel
    private let tab: FeedTab
    private let detailRouteBuilder: (Movie) -> Route
    private let tvShowDetailRouteBuilder: (TVShow) -> Route

    public init(
        tab: FeedTab,
        apiService: APIServiceProtocol,
        analyticsTracker: AnalyticsTracker? = nil,
        detailRouteBuilder: @escaping (Movie) -> Route,
        tvShowDetailRouteBuilder: @escaping (TVShow) -> Route
    ) {
        self.tab = tab
        self.detailRouteBuilder = detailRouteBuilder
        self.tvShowDetailRouteBuilder = tvShowDetailRouteBuilder
        _movieViewModel = StateObject(wrappedValue: MovieFeedViewModel(
            apiService: apiService,
            analyticsTracker: analyticsTracker
        ))
        _tvShowViewModel = StateObject(wrappedValue: TVShowFeedViewModel(
            apiService: apiService,
            analyticsTracker: analyticsTracker
        ))
    }

    public var body: some View {
        content
            .accessibilityIdentifier("feed_destination_\(tab.rawValue)")
            .navigationTitle(tab.title)
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        if let feedType = tab.movieFeedType {
            MovieFeedTabContent(
                viewModel: movieViewModel,
                feedType: feedType,
                detailRouteBuilder: detailRouteBuilder
            )
        } else if let feedType = tab.tvShowFeedType {
            TVShowFeedTabContent(
                viewModel: tvShowViewModel,
                feedType: feedType,
                detailRouteBuilder: tvShowDetailRouteBuilder
            )
        }
        // No `else`: every `FeedTab` has either a movie or a TV feed type.
    }
}
