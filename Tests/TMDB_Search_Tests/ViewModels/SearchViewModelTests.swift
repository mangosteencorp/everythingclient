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

    func search(
        scope: SearchScope,
        query _: String,
        filters: SearchFilters,
        page _: Int?
    ) async -> Result<SearchResultPage, Error> {
        scopes.append(scope)
        self.filters.append(filters)
        return .success(SearchResultPage(items: [], page: 1, totalPages: 1))
    }
}
