import Tests_Shared_Helpers
@testable import TMDB_Search
@testable import TMDB_Shared_Backend
import XCTest

/// Every scope has to reach its own TMDB endpoint and come back as the same row type — that is
/// the whole contract the search page relies on.
final class TMDBSearchServiceTests: XCTestCase {
    private var requester: StubTMDBAPIRequester!
    private var service: TMDBSearchService!

    override func setUp() {
        super.setUp()
        requester = StubTMDBAPIRequester()
        service = TMDBSearchService(requester: requester)
    }

    func testEachScopeCallsItsOwnEndpoint() async throws {
        try seedAllScopes()

        let expected: [SearchScope: String] = [
            .multi: "search/multi",
            .movies: "search/movie",
            .tvShows: "search/tv",
            .people: "search/person",
            .collections: "search/collection",
            .companies: "search/company",
            .keywords: "search/keyword",
        ]

        for scope in SearchScope.allCases {
            requester = StubTMDBAPIRequester()
            service = TMDBSearchService(requester: requester)
            try seedAllScopes()

            _ = await service.search(scope: scope, query: "dune", page: nil)
            XCTAssertEqual(requester.requestedPaths, [expected[scope]], "wrong endpoint for \(scope)")
        }
    }

    func testMultiSearchDropsUnsupportedMediaTypes() async throws {
        try seedAllScopes()

        let result = await service.search(scope: .multi, query: "dune", page: nil)
        let items = try XCTUnwrap(result.get().items)

        // The payload carries a movie, a person and a "collection" entry multi cannot render.
        XCTAssertEqual(items.map(\.kind), [.movie, .person])
        XCTAssertEqual(items.first?.title, "Dune")
        XCTAssertEqual(items.first?.tmdbID, 1)
    }

    func testEmptyQueryShortCircuitsWithoutCallingTheAPI() async {
        let result = await service.search(scope: .movies, query: "   ", page: nil)

        XCTAssertTrue(requester.requestedPaths.isEmpty)
        XCTAssertEqual(try? result.get().items.count, 0)
    }

    func testKeywordResultsBecomeRowsWithoutArtwork() async throws {
        try seedAllScopes()

        let result = await service.search(scope: .keywords, query: "dune", page: nil)
        let item = try XCTUnwrap(result.get().items.first)

        XCTAssertEqual(item.kind, .keyword)
        XCTAssertEqual(item.title, "desert")
        XCTAssertNil(item.imagePath)
    }

    func testPaginationIsReportedFromTheResponse() async throws {
        try seedAllScopes()

        let page = try await service.search(scope: .movies, query: "dune", page: nil).get()

        XCTAssertEqual(page.page, 1)
        XCTAssertEqual(page.totalPages, 3)
        XCTAssertTrue(page.hasMore)
    }

    // MARK: - Filters

    func testMovieScopeForwardsEveryFilterItSupports() async throws {
        try seedAllScopes()
        let filters = SearchFilters(
            includeAdult: true,
            language: "fr",
            primaryReleaseYear: "2021",
            region: "FR",
            year: "2020"
        )

        _ = await service.search(scope: .movies, query: "dune", filters: filters, page: nil)

        let query = try XCTUnwrap(requester.requestedEndpoints.first?.extraQuery())
        XCTAssertEqual(query["include_adult"], "true")
        XCTAssertEqual(query["language"], "fr")
        XCTAssertEqual(query["primary_release_year"], "2021")
        XCTAssertEqual(query["region"], "FR")
        XCTAssertEqual(query["year"], "2020")
    }

    /// `search/keyword` takes nothing but `query` and `page`, so a filter left over from the
    /// movie scope must not ride along.
    func testScopesDropFiltersTheirEndpointCannotHonour() async throws {
        try seedAllScopes()
        let filters = SearchFilters(includeAdult: true, language: "fr", region: "FR", year: "2020")

        _ = await service.search(scope: .keywords, query: "dune", filters: filters, page: nil)

        let query = try XCTUnwrap(requester.requestedEndpoints.first?.extraQuery())
        XCTAssertEqual(Set(query.keys), ["query"])
    }

    /// `search/person` accepts only `include_adult` and `language`; the year and region chips
    /// are not offered there and must not be sent either.
    func testPersonScopeSendsOnlyTheTwoFiltersItAccepts() async throws {
        try seedAllScopes()
        let filters = SearchFilters(includeAdult: true, language: "ja", region: "JP", year: "1999")

        _ = await service.search(scope: .people, query: "dune", filters: filters, page: nil)

        let query = try XCTUnwrap(requester.requestedEndpoints.first?.extraQuery())
        XCTAssertEqual(query["include_adult"], "true")
        XCTAssertEqual(query["language"], "ja")
        XCTAssertNil(query["region"])
        XCTAssertNil(query["year"])
    }

    /// The TV endpoint spells its year filter `first_air_date_year`, so the single year chip has
    /// to reach both spellings rather than silently doing nothing.
    func testTVScopeMapsTheYearChipOntoFirstAirDateYear() async throws {
        try seedAllScopes()

        _ = await service.search(
            scope: .tvShows,
            query: "dune",
            filters: SearchFilters(year: "2020"),
            page: nil
        )

        let query = try XCTUnwrap(requester.requestedEndpoints.first?.extraQuery())
        XCTAssertEqual(query["first_air_date_year"], "2020")
    }

    func testEveryScopeOnlyOffersChipsItsEndpointAccepts() {
        XCTAssertEqual(SearchScope.keywords.supportedFilters, [])
        XCTAssertEqual(SearchScope.companies.supportedFilters, [])
        XCTAssertFalse(SearchScope.tvShows.supportedFilters.contains(.primaryReleaseYear))
        XCTAssertEqual(SearchScope.movies.supportedFilters.count, FilterType.allCases.count)
    }

    func testNarrowingClearsFiltersTheScopeDoesNotSupport() {
        let filters = SearchFilters(
            includeAdult: true,
            language: "fr",
            primaryReleaseYear: "2021",
            region: "FR",
            year: "2020"
        )

        XCTAssertEqual(filters.narrowed(to: .movies), filters)
        XCTAssertFalse(filters.narrowed(to: .keywords).hasActiveFilters)
        XCTAssertNil(filters.narrowed(to: .people).region)
        XCTAssertNil(filters.narrowed(to: .tvShows).primaryReleaseYear)
        XCTAssertEqual(filters.narrowed(to: .tvShows).year, "2020")
    }

    // MARK: - Fixtures

    private func seedAllScopes() throws {
        requester.stub(.searchMulti(query: "dune"), with: try JSONFixture.decode(
            TrendingAllResultModel.self,
            from: """
            {
              "page": 1, "total_pages": 2, "total_results": 3,
              "results": [
                {"adult": false, "id": 1, "title": "Dune", "media_type": "movie",
                 "popularity": 10.0, "overview": "", "poster_path": "/p.jpg"},
                {"adult": false, "id": 2, "name": "Denis", "media_type": "person",
                 "popularity": 9.0, "profile_path": "/d.jpg"},
                {"adult": false, "id": 3, "name": "Dune Collection", "media_type": "collection",
                 "popularity": 8.0}
              ]
            }
            """
        ))

        requester.stub(.searchMovie(query: "dune"), with: try JSONFixture.decode(
            MovieListResultModel.self,
            from: """
            {
              "page": 1, "total_pages": 3, "total_results": 42,
              "results": [{"id": 1, "title": "Dune", "overview": "", "poster_path": "/p.jpg",
                           "vote_average": 8.1, "release_date": "2021-10-22"}]
            }
            """
        ))

        requester.stub(.searchTVShows(query: "dune"), with: try JSONFixture.decode(
            TVShowListResultModel.self,
            from: """
            {
              "page": 1, "total_pages": 1, "total_results": 1,
              "results": [{"adult": false, "backdrop_path": null, "genre_ids": [],
                           "id": 5, "origin_country": [], "original_language": "en",
                           "original_name": "Dune TV", "overview": "", "popularity": 3.0,
                           "poster_path": "/t.jpg", "first_air_date": "2024-01-01",
                           "name": "Dune TV", "vote_average": 7.0, "vote_count": 10}]
            }
            """
        ))

        requester.stub(.searchPerson(query: "dune"), with: try JSONFixture.decode(
            PersonListResultModel.self,
            from: """
            {
              "page": 1, "total_pages": 1, "total_results": 1,
              "results": [{"adult": false, "gender": 2, "id": 7, "known_for_department": "Directing",
                           "name": "Denis", "original_name": "Denis", "popularity": 20.0,
                           "profile_path": "/d.jpg", "known_for": []}]
            }
            """
        ))

        requester.stub(.searchCollection(query: "dune"), with: try JSONFixture.decode(
            CollectionSearchResultModel.self,
            from: """
            {
              "page": 1, "total_pages": 1, "total_results": 1,
              "results": [{"id": 9, "name": "Dune Collection", "overview": "Two parts",
                           "poster_path": "/c.jpg", "backdrop_path": null}]
            }
            """
        ))

        requester.stub(.searchCompany(query: "dune"), with: try JSONFixture.decode(
            CompanySearchResultModel.self,
            from: """
            {
              "page": 1, "total_pages": 1, "total_results": 1,
              "results": [{"id": 11, "name": "Legendary", "logo_path": "/l.jpg",
                           "origin_country": "US"}]
            }
            """
        ))

        requester.stub(.searchKeyword(query: "dune"), with: try JSONFixture.decode(
            KeywordSearchResultModel.self,
            from: """
            {
              "page": 1, "total_pages": 1, "total_results": 1,
              "results": [{"id": 13, "name": "desert"}]
            }
            """
        ))
    }
}
