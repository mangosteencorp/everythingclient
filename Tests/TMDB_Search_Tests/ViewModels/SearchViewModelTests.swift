import Combine
@testable import TMDB_Search
import XCTest

/// `@Published` publishes in `willSet`, so anything a sink reads back off the view model is still
/// the *old* value. These pin the request the view model actually sends to the value the user
/// just picked.
@MainActor
final class SearchViewModelTests: XCTestCase {
    func testScopeChangeSearchesTheNewScope() async {
        let spy = SpySearchService()
        let viewModel = SearchViewModel(service: spy)

        viewModel.query = "super"
        await searchLanded(viewModel)
        XCTAssertEqual(spy.scopes, [.multi])

        viewModel.scope = .movies
        await searchLanded(viewModel)

        XCTAssertEqual(spy.scopes.last, .movies, "the scope switch requested the scope the user left")
    }

    func testFilterChangeSearchesWithTheNewFilters() async {
        let spy = SpySearchService()
        let viewModel = SearchViewModel(service: spy)

        viewModel.scope = .movies
        viewModel.query = "super"
        await searchLanded(viewModel)
        XCTAssertNil(spy.filters.last?.primaryReleaseYear)

        viewModel.filters = SearchFilters(primaryReleaseYear: "2024")
        await searchLanded(viewModel)

        XCTAssertEqual(
            spy.filters.last?.primaryReleaseYear, "2024",
            "the filter change requested the filters the user left"
        )
    }

    /// A chip the current scope cannot send must not fire a request of its own.
    func testFilterChangeTheScopeIgnoresDoesNotSearchAgain() async {
        let spy = SpySearchService()
        let viewModel = SearchViewModel(service: spy)

        viewModel.scope = .keywords
        viewModel.query = "super"
        await searchLanded(viewModel)

        viewModel.filters = SearchFilters(primaryReleaseYear: "2024")
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(spy.scopes.count, 1)
    }

    /// "Clear All" is a filter change like any other: the unfiltered results come back.
    func testClearingFiltersSearchesAgainWithoutThem() async {
        let spy = SpySearchService()
        let viewModel = SearchViewModel(service: spy)

        viewModel.scope = .tvShows
        viewModel.query = "super"
        await searchLanded(viewModel)
        viewModel.filters.firstAirDateYear = "2019"
        await searchLanded(viewModel)
        XCTAssertEqual(spy.filters.last?.firstAirDateYear, "2019")
        XCTAssertTrue(viewModel.hasActiveFilters)

        viewModel.filters.clearAll()
        await searchLanded(viewModel)

        XCTAssertEqual(spy.filters.last, SearchFilters())
        XCTAssertFalse(viewModel.hasActiveFilters)
    }

    /// Done on a picker nobody changed writes back the same filters; that is not a new search.
    func testWritingBackTheSameFiltersDoesNotSearchAgain() async {
        let spy = SpySearchService()
        let viewModel = SearchViewModel(service: spy)

        viewModel.scope = .movies
        viewModel.query = "super"
        await searchLanded(viewModel)

        viewModel.filters = SearchFilters()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(spy.scopes.count, 1)
    }

    /// The chip row counts only what the current scope would send, so a movie-only filter does
    /// not light up "Clear All" on TV.
    func testActiveFiltersFollowTheScope() {
        let viewModel = SearchViewModel(service: SpySearchService(), recentsStore: InMemoryRecentSearchesStore())
        viewModel.filters = SearchFilters(primaryReleaseYear: "2021")

        viewModel.scope = .movies
        XCTAssertTrue(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.availableFilters, [.includeAdult, .language, .primaryReleaseYear, .region, .year])

        viewModel.scope = .tvShows
        XCTAssertFalse(viewModel.hasActiveFilters)
        XCTAssertEqual(viewModel.availableFilters, [.includeAdult, .language, .firstAirDateYear, .year])
    }

    // MARK: - Recent searches

    func testSavingARecentSearchPutsItFirstAndPersistsIt() {
        let store = InMemoryRecentSearchesStore(["Alien"])
        let viewModel = SearchViewModel(service: SpySearchService(), recentsStore: store)

        viewModel.query = "  Dune  "
        viewModel.saveRecentSearch()

        XCTAssertEqual(viewModel.recentSearches, ["Dune", "Alien"])
        XCTAssertEqual(store.load(), ["Dune", "Alien"], "the list did not reach the store")
    }

    /// Searching "dune" again after "Dune" moves the entry up rather than listing it twice.
    func testSavingAnExistingSearchMovesItUpCaseInsensitively() {
        let viewModel = SearchViewModel(
            service: SpySearchService(),
            recentsStore: InMemoryRecentSearchesStore(["Alien", "Dune", "Heat"])
        )

        viewModel.query = "dune"
        viewModel.saveRecentSearch()

        XCTAssertEqual(viewModel.recentSearches, ["dune", "Alien", "Heat"])
    }

    func testRecentSearchesKeepOnlyTheNewest() {
        let viewModel = SearchViewModel(service: SpySearchService(), recentsStore: InMemoryRecentSearchesStore())

        for index in 1...(SearchViewModel.maxRecentSearches + 2) {
            viewModel.query = "query \(index)"
            viewModel.saveRecentSearch()
        }

        XCTAssertEqual(viewModel.recentSearches.count, SearchViewModel.maxRecentSearches)
        XCTAssertEqual(viewModel.recentSearches.first, "query \(SearchViewModel.maxRecentSearches + 2)")
    }

    func testBlankQueryIsNeverSaved() {
        let viewModel = SearchViewModel(service: SpySearchService(), recentsStore: InMemoryRecentSearchesStore())

        viewModel.query = "   "
        viewModel.saveRecentSearch()

        XCTAssertEqual(viewModel.recentSearches, [])
    }

    func testSelectingARecentSearchRunsItAndMovesItUp() async {
        let spy = SpySearchService()
        let viewModel = SearchViewModel(service: spy, recentsStore: InMemoryRecentSearchesStore(["Alien", "Dune"]))

        viewModel.selectRecentSearch("Dune")
        await searchLanded(viewModel)

        XCTAssertEqual(viewModel.query, "Dune")
        XCTAssertEqual(spy.queries.last, "Dune")
        XCTAssertEqual(viewModel.recentSearches, ["Dune", "Alien"])
    }

    func testRemovingAndClearingRecentSearches() {
        let store = InMemoryRecentSearchesStore(["Alien", "Dune", "Heat"])
        let viewModel = SearchViewModel(service: SpySearchService(), recentsStore: store)

        viewModel.removeRecentSearch("Dune")
        XCTAssertEqual(viewModel.recentSearches, ["Alien", "Heat"])

        viewModel.clearRecentSearches()
        XCTAssertEqual(viewModel.recentSearches, [])
        XCTAssertEqual(store.load(), [])
    }

    func testUserDefaultsStoreRoundTrips() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: #function))
        defer { defaults.removePersistentDomain(forName: #function) }
        let store = UserDefaultsRecentSearchesStore(defaults: defaults)

        XCTAssertEqual(store.load(), [])
        store.save(["Dune", "Alien"])
        XCTAssertEqual(UserDefaultsRecentSearchesStore(defaults: defaults).load(), ["Dune", "Alien"])
    }

    // MARK: - Idle page

    func testIdleUntilSomethingIsTyped() {
        let viewModel = SearchViewModel(service: SpySearchService(), recentsStore: InMemoryRecentSearchesStore())
        XCTAssertTrue(viewModel.isIdle)

        viewModel.query = "  "
        XCTAssertTrue(viewModel.isIdle, "whitespace alone is not a search")

        viewModel.query = "dune"
        XCTAssertFalse(viewModel.isIdle)
    }

    func testTrendingLoadsOnce() async {
        let spy = SpySearchService()
        spy.trendingItems = [SearchResultItem(tmdbID: 1, kind: .movie, title: "Dune")]
        let viewModel = SearchViewModel(service: spy, recentsStore: InMemoryRecentSearchesStore())

        await viewModel.loadTrendingIfNeeded()
        await viewModel.loadTrendingIfNeeded()

        XCTAssertEqual(viewModel.trending.map(\.title), ["Dune"])
        XCTAssertEqual(spy.trendingCalls, 1, "trending was fetched again although it was already on screen")
    }

    // MARK: - Helpers

    /// Waits for the next completed search: `resultsGeneration` is bumped once per result set,
    /// which covers both the 300ms query debounce and the request itself.
    private func searchLanded(_ viewModel: SearchViewModel, timeout: TimeInterval = 2) async {
        let expectation = XCTestExpectation(description: "search landed")
        expectation.assertForOverFulfill = false
        let cancellable = viewModel.$resultsGeneration.dropFirst().sink { _ in expectation.fulfill() }
        await fulfillment(of: [expectation], timeout: timeout)
        cancellable.cancel()
    }
}

/// Records the scope and filters of every call, the way `StubTMDBAPIRequester.requestedPaths` does.
private final class SpySearchService: TMDBSearchServicing, @unchecked Sendable {
    private(set) var scopes: [SearchScope] = []
    private(set) var filters: [SearchFilters] = []
    private(set) var queries: [String] = []
    private(set) var trendingCalls = 0
    var trendingItems: [SearchResultItem] = []

    func search(
        scope: SearchScope,
        query: String,
        filters: SearchFilters,
        page _: Int?
    ) async -> Result<SearchResultPage, Error> {
        scopes.append(scope)
        self.filters.append(filters)
        queries.append(query)
        return .success(SearchResultPage(items: [], page: 1, totalPages: 1))
    }

    func trending() async -> Result<[SearchResultItem], Error> {
        trendingCalls += 1
        return .success(trendingItems)
    }
}
