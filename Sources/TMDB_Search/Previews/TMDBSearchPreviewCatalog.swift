#if DEBUG
import SwiftUI
import TMDB_Shared_UI

/// Every search preview as a view of its own, so Xcode's canvas, the integration launcher and
/// the screenshot run all render the same thing. Everything is backed by `StubSearchService`.
public enum TMDBSearchPreviewCatalog: String, CaseIterable {
    case allScopes
    case moviesFiltered
    case tvShowsFirstAirYear
    case collectionsRegion
    case keywords
    case people
    case idleRecentsAndTrending
    case idleFirstLaunchOffline
    case noHits
    case error
    case loading

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .allScopes:
            TMDBSearchDemoView()
        case .moviesFiltered:
            Self.page(scope: .movies, filters: SearchFilters(primaryReleaseYear: "2024", region: "US"))
        case .tvShowsFirstAirYear:
            Self.page(scope: .tvShows, filters: SearchFilters(language: "ja", firstAirDateYear: "2019"))
        case .collectionsRegion:
            Self.page(scope: .collections, filters: SearchFilters(region: "GB"))
        case .keywords:
            Self.page(SearchViewModel.previewLoaded(scope: .keywords))
        case .people:
            Self.page(SearchViewModel.previewLoaded(scope: .people))
        case .idleRecentsAndTrending:
            Self.page(SearchViewModel.previewLoaded(query: ""))
        case .idleFirstLaunchOffline:
            Self.page(SearchViewModel.previewLoaded(
                query: "",
                service: StubSearchService(failure: URLError(.notConnectedToInternet)),
                recents: []
            ))
        case .noHits:
            Self.page(SearchViewModel.previewLoaded(scope: .companies, service: StubSearchService(itemsPerPage: 0)))
        case .error:
            Self.page(SearchViewModel.previewLoaded(service: StubSearchService(failure: URLError(.notConnectedToInternet))))
        case .loading:
            Self.page(SearchViewModel.previewLoaded(service: StubSearchService(delay: .seconds(60))))
        }
    }

    @MainActor
    private static func page(scope: SearchScope, filters: SearchFilters) -> some View {
        let viewModel = SearchViewModel.previewLoaded(scope: scope)
        viewModel.filters = filters
        return page(viewModel)
    }

    @MainActor
    private static func page(_ viewModel: SearchViewModel) -> some View {
        NavigationStack {
            SearchPage(viewModel: viewModel, routeBuilder: { _ in 1 })
        }
    }
}
#endif
