#if DEBUG
import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend
import TMDB_Shared_UI

/// Every feed preview as a view of its own, so Xcode's canvas, the integration launcher and the
/// screenshot run all render the same thing. Everything but `demo` is served by
/// `PreviewFeedAPIService`; `demo` is the live feed.
///
/// The `items…` cases pick their layout in the shared `DesignCoordinator`, which saves it like
/// any other design choice.
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
    case itemsList
    case itemsCompactRows
    case itemsGrid
    case itemsPaletteCards
    case itemRows

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
        default:
            content
        }
    }

    @MainActor @ViewBuilder
    private var content: some View {
        switch self {
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
        case .itemsList:
            FeedItemsPreview(design: .list)
        case .itemsCompactRows:
            FeedItemsPreview(design: .compactRows)
        case .itemsGrid:
            FeedItemsPreview(design: .grid)
        case .itemsPaletteCards:
            FeedItemsPreview(design: .paletteCards)
        case .itemRows:
            NavigationStack {
                List {
                    FeedItemRow(item: Movie.previewMovies[0].feedItem(route: 1), style: .list, onAppear: {})
                    FeedItemRow(item: Movie.previewMovies[1].feedItem(route: 2), style: .compactRows, onAppear: {})
                }
            }
        default:
            EmptyView()
        }
    }
}

/// `FeedItemsView` reads its layout from the shared design coordinator, so each preview picks
/// one there; the private cells are only reachable through their layout.
private struct FeedItemsPreview: View {
    let design: FeedContentDesign

    var body: some View {
        NavigationStack {
            FeedItemsView(
                items: Movie.previewMovies.map { $0.feedItem(route: $0.id) },
                accessibilityIdentifier: "preview",
                onItemAppear: { _ in }
            )
        }
        .onAppear { DesignCoordinator.shared.select(design) }
    }
}
#endif
