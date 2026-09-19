import Tests_Shared_Helpers
@testable import TMDB_Feed
import TMDB_Shared_Backend
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
