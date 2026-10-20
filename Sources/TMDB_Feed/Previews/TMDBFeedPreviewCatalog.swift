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
    case listPage
    case listPageInNavigation
    case destinationMovies
    case destinationTVShows
    case tabContainer
    case topSegmentsLayout
    case systemLayout
    case movieContentLoaded
    case movieContentOffline
    case tvShowContent
    case itemsList
    case itemsCompactRows
    case itemsGrid
    case itemsPaletteCards
    case itemRows
    case listPageNavigation

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .demo:
            TMDBFeedDemoView()
        case .listPage:
            MovieFeedListPage(apiService: PreviewFeedAPIService(), detailRouteBuilder: { $0.id }, tvShowDetailRouteBuilder: { $0.id })
        case .listPageInNavigation:
            NavigationStack {
                MovieFeedListPage(
                    movieViewModel: MovieFeedViewModel(apiService: PreviewFeedAPIService()),
                    tvShowViewModel: TVShowFeedViewModel(apiService: PreviewFeedAPIService()),
                    detailRouteBuilder: { $0.id },
                    tvShowDetailRouteBuilder: { $0.id }
                )
            }
        case .destinationMovies, .destinationTVShows:
            NavigationStack {
                FeedDestinationPage(
                    tab: self == .destinationMovies ? .nowPlaying : .airingToday,
                    apiService: PreviewFeedAPIService(),
                    detailRouteBuilder: { $0.id },
                    tvShowDetailRouteBuilder: { $0.id }
                )
            }
        case .tabContainer, .topSegmentsLayout, .systemLayout:
            tabLayout
        default:
            content
        }
    }

    @MainActor @ViewBuilder
    private var tabLayout: some View {
        let initialTab: FeedTab = self == .topSegmentsLayout ? .popular : .nowPlaying
        StatefulPreview(initialTab) { selection in
            StatefulPreview(initialTab) { visibleTab in
                switch self {
                case .topSegmentsLayout:
                    TopSegmentsFeedTabLayout(tabs: FeedTab.allCases, selection: selection, visibleTab: visibleTab) { Text($0.title) }
                case .systemLayout:
                    SystemFeedTabLayout(tabs: FeedTab.allCases, selection: selection, visibleTab: visibleTab) { Text($0.title) }
                default:
                    FeedTabContainer(tabs: FeedTab.allCases, selection: selection, visibleTab: visibleTab) { Text($0.title) }
                }
            }
        }
    }

    @MainActor @ViewBuilder
    private var content: some View {
        switch self {
        case .movieContentLoaded:
            NavigationStack {
                MovieFeedTabContent(
                    viewModel: MovieFeedViewModel(apiService: PreviewFeedAPIService()),
                    feedType: .popular,
                    detailRouteBuilder: { $0.id }
                )
            }
        case .movieContentOffline:
            MovieFeedTabContent(
                viewModel: MovieFeedViewModel(apiService: PreviewFeedAPIService(failure: URLError(.notConnectedToInternet))),
                feedType: .popular,
                detailRouteBuilder: { $0.id }
            )
        case .tvShowContent:
            NavigationStack {
                TVShowFeedTabContent(
                    viewModel: TVShowFeedViewModel(apiService: PreviewFeedAPIService()),
                    feedType: .onTheAir,
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
            MovieFeedListPageNavigation()
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
