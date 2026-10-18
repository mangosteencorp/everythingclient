import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

/// One TMDB feed — a movie list or a TV list — and nothing else. Hosts that show several feeds
/// (tabs, sidebar sections) put one `FeedPage` per feed; each owns its own view model.
@available(iOS 16, *)
public struct FeedPage<Route: Hashable>: View {
    private let kind: FeedKind
    private let apiService: APIServiceProtocol
    private let additionalParams: AdditionalMovieListParams?
    private let analyticsTracker: AnalyticsTracker?
    private let detailRouteBuilder: (Movie) -> Route
    private let tvShowDetailRouteBuilder: (TVShow) -> Route

    public init(
        kind: FeedKind,
        apiService: APIServiceProtocol,
        additionalParams: AdditionalMovieListParams? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        detailRouteBuilder: @escaping (Movie) -> Route,
        tvShowDetailRouteBuilder: @escaping (TVShow) -> Route
    ) {
        self.kind = kind
        self.apiService = apiService
        self.additionalParams = additionalParams
        self.analyticsTracker = analyticsTracker
        self.detailRouteBuilder = detailRouteBuilder
        self.tvShowDetailRouteBuilder = tvShowDetailRouteBuilder
    }

    public var body: some View {
        content
            // Another feed in the same spot gets a fresh view model, not the previous feed's.
            .id(kind)
            .accessibilityIdentifier("feed_destination_\(kind.rawValue)")
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        if let feedType = kind.movieFeedType {
            MovieFeedOwner(
                viewModel: MovieFeedViewModel(
                    feedType: feedType,
                    apiService: apiService,
                    additionalParams: additionalParams,
                    analyticsTracker: analyticsTracker
                ),
                detailRouteBuilder: detailRouteBuilder
            )
        } else if let feedType = kind.tvShowFeedType {
            TVShowFeedOwner(
                viewModel: TVShowFeedViewModel(
                    feedType: feedType,
                    apiService: apiService,
                    additionalParams: additionalParams,
                    analyticsTracker: analyticsTracker
                ),
                detailRouteBuilder: tvShowDetailRouteBuilder
            )
        }
        // No `else`: every `FeedKind` has either a movie or a TV feed type.
    }
}

/// Keeps the view model alive across parent redraws; the content view only observes it.
@available(iOS 16, *)
private struct MovieFeedOwner<Route: Hashable>: View {
    @StateObject private var viewModel: MovieFeedViewModel
    let detailRouteBuilder: (Movie) -> Route

    init(viewModel: @autoclosure @escaping () -> MovieFeedViewModel, detailRouteBuilder: @escaping (Movie) -> Route) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.detailRouteBuilder = detailRouteBuilder
    }

    var body: some View {
        MovieFeedContent(viewModel: viewModel, detailRouteBuilder: detailRouteBuilder)
    }
}

@available(iOS 16, *)
private struct TVShowFeedOwner<Route: Hashable>: View {
    @StateObject private var viewModel: TVShowFeedViewModel
    let detailRouteBuilder: (TVShow) -> Route

    init(viewModel: @autoclosure @escaping () -> TVShowFeedViewModel, detailRouteBuilder: @escaping (TVShow) -> Route) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.detailRouteBuilder = detailRouteBuilder
    }

    var body: some View {
        TVShowFeedContent(viewModel: viewModel, detailRouteBuilder: detailRouteBuilder)
    }
}

#if DEBUG
#Preview("Movies") {
    TMDBFeedPreviewCatalog.pageMovies.view
}

#Preview("TV shows") {
    TMDBFeedPreviewCatalog.pageTVShows.view
}
#endif
