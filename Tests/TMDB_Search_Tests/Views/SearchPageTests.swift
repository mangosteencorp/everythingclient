import SwiftUI
@testable import TMDB_Search
import TMDB_Shared_UI
import ViewInspector
import XCTest

/// The search page's chip row is driven entirely by the scope, because TMDB accepts a different
/// query-parameter set per search endpoint.
@available(iOS 16.0, *)
@MainActor
final class SearchPageTests: XCTestCase {
    func testShowsFilterChipsForScopesThatSupportThem() throws {
        let page = SearchPage(
            viewModel: SearchViewModel(service: StubSearchService()),
            routeBuilder: { _ in 1 }
        )

        XCTAssertNoThrow(try page.inspect().find(FilterChipsView.self))
    }

    /// `search/keyword` takes nothing but a query, so offering chips there would be a lie.
    func testHidesFilterChipsForKeywordScope() throws {
        let viewModel = SearchViewModel(service: StubSearchService())
        viewModel.scope = .keywords
        let page = SearchPage(viewModel: viewModel, routeBuilder: { _ in 1 })

        XCTAssertThrowsError(try page.inspect().find(FilterChipsView.self))
    }

    /// Before a query is typed the page shows the placeholder, not an empty-results screen —
    /// the distinction `SearchViewModel.hasSearched` exists for.
    func testPlaceholderBeforeFirstQuery() throws {
        let view = SearchPage(
            viewModel: SearchViewModel(service: StubSearchService()),
            routeBuilder: { _ in 1 }
        )

        XCTAssertNoThrow(try view.inspect().find(FeedPlaceholderView.self))
        XCTAssertThrowsError(try view.inspect().find(ViewType.List.self))
    }

    /// The scope picker is the one place the seven endpoints are exposed, so its contents are
    /// worth pinning the way the feed tabs are.
    func testScopeFingerprint() {
        let fingerprint = SearchScope.allCases.map { "\($0.id):\($0.systemImage)" }
        XCTAssertEqual(
            fingerprint,
            [
                "multi:sparkle.magnifyingglass",
                "movies:film",
                "tvShows:tv",
                "people:person.2",
                "collections:square.stack",
                "companies:building.2",
                "keywords:tag",
            ]
        )
    }
}
