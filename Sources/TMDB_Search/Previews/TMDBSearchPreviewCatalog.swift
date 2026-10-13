#if DEBUG
import SwiftUI
import TMDB_Shared_UI

/// Every search preview as a view of its own, so Xcode's canvas, the integration launcher and
/// the screenshot run all render the same thing. Everything is backed by `StubSearchService`.
public enum TMDBSearchPreviewCatalog: String, CaseIterable {
    // Search page
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
    case darkMode
    case fieldPinnedUnderTitle
    case resultRowsEveryKind
    case resultsListMorePages
    // Filter sheets
    case filterIncludeAdult
    case filterLanguage
    case filterRegion
    case filterReleaseYear
    case filterFirstAirYear
    case filterYear
    case filterValueWheel
    // Idle page
    case idleView
    case idleViewEmpty
    case recentSearchRow
    case sectionHeader
    case posterCards
    // Result rows
    case rowEveryKind
    case rowAccessibilitySize
    case artworkEveryKind
    case kindBadges
    case rating
    // Filter chips
    case chipEveryFilter
    case chipRowNoneActive
    case chipRowSomeActive
    case chipRowEachScope
    // Scope bar
    case scopeBar
    case scopeButton

    @MainActor @ViewBuilder
    public var view: some View {
        switch self {
        case .allScopes, .moviesFiltered, .tvShowsFirstAirYear, .collectionsRegion, .keywords, .people,
             .idleRecentsAndTrending, .idleFirstLaunchOffline, .noHits, .error, .loading, .darkMode,
             .fieldPinnedUnderTitle, .resultRowsEveryKind, .resultsListMorePages:
            searchPage
        case .filterIncludeAdult, .filterLanguage, .filterRegion, .filterReleaseYear, .filterFirstAirYear,
             .filterYear, .filterValueWheel:
            filterSheet
        case .idleView, .idleViewEmpty, .recentSearchRow, .sectionHeader, .posterCards:
            idlePage
        case .rowEveryKind, .rowAccessibilitySize, .artworkEveryKind, .kindBadges, .rating:
            resultRow
        case .chipEveryFilter, .chipRowNoneActive, .chipRowSomeActive, .chipRowEachScope, .scopeBar, .scopeButton:
            chips
        }
    }
}

extension TMDBSearchPreviewCatalog {
    @MainActor @ViewBuilder
    private var searchPage: some View {
        switch self {
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
        case .darkMode:
            TMDBSearchDemoView()
                .preferredColorScheme(.dark)
        case .fieldPinnedUnderTitle:
            TMDBSearchDemoView(scope: .movies)
                .environment(\.searchPageFieldPlacement, .navigationBarDrawer(displayMode: .always))
        case .resultRowsEveryKind:
            List {
                ForEach(SearchScope.allCases) { scope in
                    Section(scope.title) {
                        ForEach(StubSearchService.items(for: scope, query: "super", page: 1).prefix(2)) { item in
                            SearchResultRow(item: item, showsKind: scope == .multi)
                        }
                    }
                }
            }
        case .resultsListMorePages:
            NavigationStack {
                SearchResultsList(
                    items: StubSearchService.items(for: .multi, query: "super", page: 1, count: 4),
                    showsKind: true,
                    canLoadMore: true,
                    resultsGeneration: 0,
                    routeBuilder: { _ in 1 },
                    onRowAppear: { _ in }
                )
            }
        default:
            TMDBSearchDemoView()
        }
    }

    @MainActor @ViewBuilder
    private var filterSheet: some View {
        switch self {
        case .filterIncludeAdult:
            FilterSheetPreview(filterType: .includeAdult, filters: SearchFilters(includeAdult: true))
        case .filterLanguage:
            FilterSheetPreview(filterType: .language, filters: SearchFilters(language: "fr"))
        case .filterRegion:
            FilterSheetPreview(filterType: .region, filters: SearchFilters())
        case .filterReleaseYear:
            FilterSheetPreview(filterType: .primaryReleaseYear, filters: SearchFilters(primaryReleaseYear: "2024"))
        case .filterFirstAirYear:
            FilterSheetPreview(filterType: .firstAirDateYear, filters: SearchFilters())
        case .filterYear:
            FilterSheetPreview(filterType: .year, filters: SearchFilters(year: "1984"))
        default:
            StatefulPreview(String?.some("JP")) { FilterValuePicker(filterType: .region, selection: $0) }
        }
    }

    @MainActor @ViewBuilder
    private var idlePage: some View {
        switch self {
        case .idleView:
            NavigationStack {
                SearchIdleView(
                    recents: SearchViewModel.previewRecents,
                    trending: StubSearchService.items(for: .multi, query: "trending", page: 1, count: 8),
                    routeBuilder: { _ in 1 },
                    onSelectRecent: { _ in },
                    onRemoveRecent: { _ in },
                    onClearRecents: {}
                )
            }
        case .idleViewEmpty:
            SearchIdleView<Int>(
                recents: [],
                trending: [],
                routeBuilder: { _ in nil },
                onSelectRecent: { _ in },
                onRemoveRecent: { _ in },
                onClearRecents: {}
            )
        case .recentSearchRow:
            List {
                RecentSearchRow(query: "The Lord of the Rings") {}
            }
            .listStyle(.plain)
        case .sectionHeader:
            List {
                Section {
                    Text("Dune")
                } header: {
                    SearchSectionHeader(title: "Recent Searches") {
                        Button("Clear") {}
                    }
                }
                .headerProminence(.increased)
            }
            .listStyle(.plain)
        default:
            HStack(alignment: .top) {
                ForEach(StubSearchService.items(for: .multi, query: "super", page: 1, count: 3)) { item in
                    SearchPosterCard(item: item)
                }
            }
            .padding()
        }
    }

    @MainActor @ViewBuilder
    private var resultRow: some View {
        switch self {
        case .rowEveryKind:
            List {
                ForEach(SearchScope.allCases.dropFirst()) { scope in
                    ForEach(StubSearchService.items(for: scope, query: "super", page: 1).prefix(1)) { item in
                        SearchResultRow(item: item, showsKind: true)
                    }
                }
            }
            .listStyle(.plain)
        case .rowAccessibilitySize:
            List(StubSearchService.items(for: .multi, query: "super", page: 1).prefix(3)) { item in
                SearchResultRow(item: item, showsKind: true)
            }
            .listStyle(.plain)
            .dynamicTypeSize(.accessibility2)
        case .artworkEveryKind:
            HStack(alignment: .top) {
                ForEach(SearchScope.allCases.dropFirst()) { scope in
                    if let item = StubSearchService.items(for: scope, query: "super", page: 1, count: 1).first {
                        SearchArtwork(item: SearchResultItem(tmdbID: item.tmdbID, kind: item.kind, title: item.title), width: 44)
                    }
                }
            }
            .padding()
        case .kindBadges:
            VStack(alignment: .leading) {
                ForEach([SearchResultKind.movie, .tvShow, .person, .collection, .company, .keyword], id: \.self) { kind in
                    SearchKindBadge(kind: kind)
                }
            }
        default:
            VStack {
                SearchRatingLabel(voteAverage: 8.123)
                SearchRatingLabel(voteAverage: 5)
            }
        }
    }

    @MainActor @ViewBuilder
    private var chips: some View {
        switch self {
        case .chipEveryFilter:
            VStack(alignment: .leading, spacing: 12) {
                ForEach(FilterType.allCases) { filterType in
                    HStack {
                        FilterChip(filterType: filterType, onTap: {}, onRemove: {})
                        FilterChip(
                            filterType: filterType,
                            value: Self.everyFilter.displayValue(for: filterType),
                            onTap: {},
                            onRemove: {}
                        )
                    }
                }
            }
            .padding()
        case .chipRowNoneActive:
            FilterChipsView(filters: .constant(SearchFilters()), types: SearchScope.movies.supportedFilters) { _ in }
        case .chipRowSomeActive:
            StatefulPreview(SearchFilters(language: "en-US", primaryReleaseYear: "2024")) { filters in
                FilterChipsView(filters: filters, types: SearchScope.movies.supportedFilters) { _ in }
            }
        case .chipRowEachScope:
            VStack(alignment: .leading, spacing: 4) {
                ForEach(SearchScope.allCases.filter { !$0.supportedFilters.isEmpty }) { scope in
                    Text(scope.title)
                        .font(.caption)
                        .padding(.horizontal)
                    FilterChipsView(
                        filters: .constant(SearchFilters(firstAirDateYear: "2019", region: "GB")),
                        types: scope.supportedFilters
                    ) { _ in }
                }
            }
        case .scopeBar:
            VStack(spacing: 24) {
                StatefulPreview(SearchScope.movies) { SearchScopeBar(selection: $0) }
                SearchScopeBar(selection: .constant(.keywords))
            }
        default:
            HStack {
                SearchScopeButton(scope: .multi, isSelected: true) {}
                SearchScopeButton(scope: .people, isSelected: false) {}
            }
        }
    }

    /// Every filter set, so each chip shows its "on" look.
    private static var everyFilter: SearchFilters { SearchFilters(
        includeAdult: true,
        language: "fr",
        primaryReleaseYear: "2021",
        firstAirDateYear: "2019",
        region: "JP",
        year: "1984"
    ) }

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

/// Presents the filter sheet over a blank page, the way the search page does.
private struct FilterSheetPreview: View {
    let filterType: FilterType
    @State var filters: SearchFilters

    var body: some View {
        Color.clear.sheet(isPresented: .constant(true)) {
            FilterConfigurationView(filters: $filters, filterType: filterType)
        }
    }
}
#endif
