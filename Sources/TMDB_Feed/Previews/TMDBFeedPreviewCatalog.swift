#if DEBUG
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

/// Every feed preview as a view of its own, so Xcode's canvas, the integration launcher and the
/// screenshot run all render the same thing. Everything but `demo` is served by
/// `PreviewFeedAPIService`; `demo` is the live feed.
public enum TMDBFeedPreviewCatalog: String, CaseIterable, Identifiable {
    public var id: String {
        rawValue
    }

    case demo
    case pageMovies
    case pageTVShows
    case movieContentLoaded
    case movieContentOffline
    case tvShowContent

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .demo:
            TMDBFeedDemoView()
        case .pageMovies, .pageTVShows:
            NavigationStack {
                FeedPage(
                    kind: self == .pageMovies ? .nowPlaying : .airingToday,
                    apiService: PreviewFeedAPIService(),
                    detailRouteBuilder: { $0.id },
                    tvShowDetailRouteBuilder: { $0.id }
                )
            }
        case .movieContentLoaded:
            NavigationStack {
                MovieFeedContent(
                    viewModel: MovieFeedViewModel(feedType: .popular, apiService: PreviewFeedAPIService()),
                    detailRouteBuilder: { $0.id }
                )
            }
        case .movieContentOffline:
            MovieFeedContent(
                viewModel: MovieFeedViewModel(
                    feedType: .popular,
                    apiService: PreviewFeedAPIService(failure: URLError(.notConnectedToInternet))
                ),
                detailRouteBuilder: { $0.id }
            )
        case .tvShowContent:
            NavigationStack {
                TVShowFeedContent(
                    viewModel: TVShowFeedViewModel(feedType: .onTheAir, apiService: PreviewFeedAPIService()),
                    detailRouteBuilder: { $0.id }
                )
            }
        }
    }
}
#endif
