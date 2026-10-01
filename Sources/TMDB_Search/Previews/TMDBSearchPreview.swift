import SwiftUI
import TMDB_Shared_Backend

#if DEBUG
/// A search service that answers from a fixed table instead of the network.
///
/// Search previews need every scope to render something — including the three with no artwork —
/// and a screenshot run cannot depend on what TMDB happens to return for "super" today.
@available(iOS 16, *)
public struct StubSearchService: TMDBSearchServicing {
    public var itemsPerPage: Int
    public var pagesPerScope: Int
    public var failure: Error?
    public var delay: Duration

    public init(
        itemsPerPage: Int = 12,
        pagesPerScope: Int = 3,
        failure: Error? = nil,
        delay: Duration = .zero
    ) {
        self.itemsPerPage = itemsPerPage
        self.pagesPerScope = pagesPerScope
        self.failure = failure
        self.delay = delay
    }

    public func search(
        scope: SearchScope,
        query: String,
        filters: SearchFilters,
        page: Int?
    ) async -> Result<SearchResultPage, Error> {
        if delay > .zero { try? await Task.sleep(for: delay) }
        if let failure { return .failure(failure) }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .success(SearchResultPage(items: [], page: 1, totalPages: 1))
        }

        let page = page ?? 1
        // A year filter dates every row that year, so a filtered search visibly differs from
        // an unfiltered one; like the real service, only what this scope sends counts.
        let filters = filters.narrowed(to: scope)
        let year = filters.primaryReleaseYear ?? filters.firstAirDateYear ?? filters.year
        return .success(SearchResultPage(
            items: Self.items(for: scope, query: trimmed, page: page, count: itemsPerPage, year: year),
            page: page,
            totalPages: max(pagesPerScope, 1)
        ))
    }

    public func trending() async -> Result<[SearchResultItem], Error> {
        if let failure { return .failure(failure) }
        return .success(Self.items(for: .multi, query: "Trending", page: 1, count: itemsPerPage))
    }

    static func items(
        for scope: SearchScope,
        query: String,
        page: Int,
        count: Int = 12,
        year: String? = nil
    ) -> [SearchResultItem] {
        let kinds: [SearchResultKind]
        switch scope {
        case .multi: kinds = [.movie, .tvShow, .person]
        case .movies: kinds = [.movie]
        case .tvShows: kinds = [.tvShow]
        case .people: kinds = [.person]
        case .collections: kinds = [.collection]
        case .companies: kinds = [.company]
        case .keywords: kinds = [.keyword]
        }

        return (0..<max(count, 0)).map { index in
            let kind = kinds[index % kinds.count]
            return SearchResultItem(
                tmdbID: page * 1000 + index,
                kind: kind,
                title: "\(query.capitalized) \(kind.sampleNoun) \(page * count + index + 1)",
                subtitle: kind.sampleSubtitle(year: year),
                overview: kind.sampleOverview,
                // Keywords and companies really have no artwork; the stub keeps that true so
                // the icon fallback stays exercised.
                imagePath: kind.hasArtwork ? "/stub\(index).jpg" : nil,
                voteAverage: kind.hasScore ? Double(55 + (index * 3) % 45) / 10 : nil
            )
        }
    }
}

@available(iOS 16, *)
private extension SearchResultKind {
    var sampleNoun: String {
        switch self {
        case .movie: return "Movie"
        case .tvShow: return "Series"
        case .person: return "Star"
        case .collection: return "Collection"
        case .company: return "Pictures"
        case .keyword: return "Theme"
        }
    }

    func sampleSubtitle(year: String?) -> String? {
        switch self {
        case .movie, .tvShow: return "\(year ?? "2024")-05-17"
        case .person: return "Acting"
        case .company: return "US"
        case .collection, .keyword: return nil
        }
    }

    var sampleOverview: String? {
        switch self {
        case .movie, .tvShow: return "A hero rises, falls and rises again, in a story long enough to need two lines."
        case .person: return "Super Movie, Super Series"
        case .collection: return "Every film in the series, in order."
        case .company, .keyword: return nil
        }
    }

    var hasArtwork: Bool {
        switch self {
        case .movie, .tvShow, .person, .collection: return true
        case .company, .keyword: return false
        }
    }

    var hasScore: Bool {
        switch self {
        case .movie, .tvShow: return true
        case .person, .collection, .company, .keyword: return false
        }
    }
}

/// Recent searches kept in memory, so a preview or UI test starts from a known list.
public final class InMemoryRecentSearchesStore: RecentSearchesStoring {
    private var searches: [String]

    public init(_ searches: [String] = []) {
        self.searches = searches
    }

    public func load() -> [String] { searches }

    public func save(_ searches: [String]) { self.searches = searches }
}

/// The search demo the screenshot run captures.
///
/// Backed by the stub so the captured image is the same on every run — the feed demos can use
/// live data because they load themselves, but a search page with no query is a blank screen.
@available(iOS 16, *)
public struct TMDBSearchDemoView: View {
    private let scope: SearchScope
    private let query: String

    public init(scope: SearchScope = .multi, query: String = "super") {
        self.scope = scope
        self.query = query
    }

    public var body: some View {
        NavigationStack {
            SearchPage(
                viewModel: SearchViewModel.previewLoaded(scope: scope, query: query),
                routeBuilder: { $0 }
            )
            // Opening a row shows which one was tapped, so UI tests can check the tap landed.
            .navigationDestination(for: SearchResultItem.self) { item in
                Text(item.title)
                    .font(.largeTitle.bold())
                    .navigationTitle(item.kind.title)
                    .accessibilityIdentifier("search.demo.detail")
            }
        }
        .accessibilityIdentifier("search.demo.page")
    }
}

@available(iOS 16, *)
extension SearchViewModel {
    /// A few past queries, so the idle page has something to show.
    static let previewRecents = ["Dune", "Christopher Nolan", "Breaking Bad"]

    /// A view model already holding results, so a preview does not open on a spinner.
    static func previewLoaded(
        scope: SearchScope = .multi,
        query: String = "super",
        service: TMDBSearchServicing = StubSearchService(),
        recents: [String] = previewRecents
    ) -> SearchViewModel {
        let viewModel = SearchViewModel(service: service, recentsStore: InMemoryRecentSearchesStore(recents))
        viewModel.scope = scope
        viewModel.query = query
        viewModel.runSearch()
        return viewModel
    }
}

// MARK: - Previews

@available(iOS 16, *)
#Preview("Search — all scopes") {
    TMDBSearchDemoView()
}

@available(iOS 16, *)
#Preview("Search — movies, filtered") {
    NavigationStack {
        SearchPage(
            viewModel: {
                let viewModel = SearchViewModel.previewLoaded(scope: .movies)
                viewModel.filters = SearchFilters(primaryReleaseYear: "2024", region: "US")
                return viewModel
            }(),
            routeBuilder: { _ in 1 }
        )
    }
}

@available(iOS 16, *)
#Preview("Search — TV shows, first air year") {
    NavigationStack {
        SearchPage(
            viewModel: {
                let viewModel = SearchViewModel.previewLoaded(scope: .tvShows)
                viewModel.filters = SearchFilters(language: "ja", firstAirDateYear: "2019")
                return viewModel
            }(),
            routeBuilder: { _ in 1 }
        )
    }
}

@available(iOS 16, *)
#Preview("Search — collections, region") {
    NavigationStack {
        SearchPage(
            viewModel: {
                let viewModel = SearchViewModel.previewLoaded(scope: .collections)
                viewModel.filters = SearchFilters(region: "GB")
                return viewModel
            }(),
            routeBuilder: { _ in 1 }
        )
    }
}

@available(iOS 16, *)
#Preview("Search — keywords (no artwork, no chips)") {
    NavigationStack {
        SearchPage(
            viewModel: SearchViewModel.previewLoaded(scope: .keywords),
            routeBuilder: { _ in 1 }
        )
    }
}

@available(iOS 16, *)
#Preview("Search — people") {
    NavigationStack {
        SearchPage(
            viewModel: SearchViewModel.previewLoaded(scope: .people),
            routeBuilder: { _ in 1 }
        )
    }
}

@available(iOS 16, *)
#Preview("Search — idle, recents and trending") {
    NavigationStack {
        SearchPage(
            viewModel: SearchViewModel.previewLoaded(query: ""),
            routeBuilder: { _ in 1 }
        )
    }
}

@available(iOS 16, *)
#Preview("Search — idle, first launch offline") {
    NavigationStack {
        SearchPage(
            viewModel: SearchViewModel.previewLoaded(
                query: "",
                service: StubSearchService(failure: URLError(.notConnectedToInternet)),
                recents: []
            ),
            routeBuilder: { _ in 1 }
        )
    }
}

@available(iOS 16, *)
#Preview("Search — no hits") {
    NavigationStack {
        SearchPage(
            viewModel: SearchViewModel.previewLoaded(
                scope: .companies,
                service: StubSearchService(itemsPerPage: 0)
            ),
            routeBuilder: { _ in 1 }
        )
    }
}

@available(iOS 16, *)
#Preview("Search — error") {
    NavigationStack {
        SearchPage(
            viewModel: SearchViewModel.previewLoaded(
                service: StubSearchService(failure: URLError(.notConnectedToInternet))
            ),
            routeBuilder: { _ in 1 }
        )
    }
}

@available(iOS 16, *)
#Preview("Search — loading") {
    NavigationStack {
        SearchPage(
            viewModel: SearchViewModel.previewLoaded(
                service: StubSearchService(delay: .seconds(60))
            ),
            routeBuilder: { _ in 1 }
        )
    }
}

@available(iOS 16, *)
#Preview("Search — dark mode") {
    TMDBSearchDemoView()
        .preferredColorScheme(.dark)
}

@available(iOS 16, *)
#Preview("Search — field pinned under the title") {
    TMDBSearchDemoView(scope: .movies)
        .environment(\.searchPageFieldPlacement, .navigationBarDrawer(displayMode: .always))
}

@available(iOS 16, *)
#Preview("Search result rows — every kind") {
    List {
        ForEach(SearchScope.allCases) { scope in
            Section(scope.title) {
                ForEach(StubSearchService.items(for: scope, query: "super", page: 1).prefix(2)) { item in
                    SearchResultRow(item: item, showsKind: scope == .multi)
                }
            }
        }
    }
}
#endif
