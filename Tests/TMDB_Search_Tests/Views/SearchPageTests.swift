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
            viewModel: SearchViewModel(service: StubSearchService(), recentsStore: InMemoryRecentSearchesStore()),
            routeBuilder: { _ in 1 }
        )

        XCTAssertNoThrow(try page.inspect().find(FilterChipsView.self))
    }

    /// `search/keyword` takes nothing but a query, so offering chips there would be a lie.
    func testHidesFilterChipsForKeywordScope() throws {
        let viewModel = SearchViewModel(service: StubSearchService(), recentsStore: InMemoryRecentSearchesStore())
        viewModel.scope = .keywords
        let page = SearchPage(viewModel: viewModel, routeBuilder: { _ in 1 })

        XCTAssertThrowsError(try page.inspect().find(FilterChipsView.self))
    }

    /// Before a query is typed the page offers recents and trending, not an empty-results
    /// screen or a spinner.
    func testIdlePageBeforeFirstQuery() throws {
        let view = SearchPage(
            viewModel: SearchViewModel(service: StubSearchService(), recentsStore: InMemoryRecentSearchesStore(["Dune"])),
            routeBuilder: { _ in 1 }
        )

        XCTAssertNoThrow(try view.inspect().find(SearchIdleView<Int>.self))
        XCTAssertNoThrow(try view.inspect().find(RecentSearchRow.self))
        XCTAssertThrowsError(try view.inspect().find(SearchResultsList<Int>.self))
    }

    /// With no recents and no trending yet, the idle page is a one-line prompt, not a blank list.
    func testIdlePageWithNothingToOfferShowsThePrompt() throws {
        let view = SearchPage(
            viewModel: SearchViewModel(service: StubSearchService(), recentsStore: InMemoryRecentSearchesStore()),
            routeBuilder: { _ in 1 }
        )

        XCTAssertNoThrow(try view.inspect().find(FeedPlaceholderView.self))
        XCTAssertThrowsError(try view.inspect().find(ViewType.List.self))
    }

    /// Every scope is one tap away in the bar, not hidden behind search focus.
    func testScopeBarOffersEveryScope() throws {
        let bar = SearchScopeBar(selection: .constant(.movies))

        let buttons = try bar.inspect().findAll(SearchScopeButton.self)
        XCTAssertEqual(try buttons.map { try $0.actualView().scope }, SearchScope.allCases)
        XCTAssertEqual(try buttons.filter { try $0.actualView().isSelected }.map { try $0.actualView().scope }, [.movies])
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
