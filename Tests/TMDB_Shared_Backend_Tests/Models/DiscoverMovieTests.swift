@testable import TMDB_Shared_Backend
import XCTest

final class DiscoverMovieTests: XCTestCase {
    func testDiscoverMovieWithCastParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "discover-mov1", withExtension: "json"))
        let data = try XCTUnwrap(Data(contentsOf: url))

        var discoverResult: MovieListResultModel?
        XCTAssertNoThrow(discoverResult = try JSONDecoder().decode(MovieListResultModel.self, from: data))

        let unwrappedResult = try XCTUnwrap(discoverResult)
        let firstMovie = try XCTUnwrap(unwrappedResult.results.first)

        XCTAssertEqual(unwrappedResult.page, 1)
        XCTAssertEqual(unwrappedResult.totalPages, 2)
        XCTAssertEqual(unwrappedResult.totalResults, 33)
        XCTAssertEqual(firstMovie.title, "The Phoenician Scheme")
        XCTAssertEqual(firstMovie.vote_average, 6.7)
        XCTAssertEqual(firstMovie.genre_ids, [12, 35])
    }

    func testDiscoverMovieWithKeywordsAndProvidersParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "discover-mov2", withExtension: "json"))
        let data = try XCTUnwrap(Data(contentsOf: url))

        var discoverResult: MovieListResultModel?
        XCTAssertNoThrow(discoverResult = try JSONDecoder().decode(MovieListResultModel.self, from: data))

        let unwrappedResult = try XCTUnwrap(discoverResult)
        let firstMovie = try XCTUnwrap(unwrappedResult.results.first)

        XCTAssertEqual(unwrappedResult.page, 1)
        XCTAssertEqual(unwrappedResult.totalPages, 225)
        XCTAssertEqual(unwrappedResult.totalResults, 4486)
        XCTAssertEqual(firstMovie.title, "Happy Gilmore 2")
        XCTAssertEqual(firstMovie.vote_average, 6.7)
        XCTAssertEqual(firstMovie.genre_ids, [35])
    }

    func testDiscoverEndpointParameters() throws {
        // Test basic discover endpoint
        let basicEndpoint = TMDBEndpoint.discoverMovie()
        XCTAssertEqual(basicEndpoint.path(), "discover/movie")
        XCTAssertEqual(basicEndpoint.extraQuery(), [:])

        // Test discover with cast
        let castEndpoint = TMDBEndpoint.discoverMovie(cast: 1245)
        let castParams = castEndpoint.extraQuery()
        XCTAssertEqual(castParams?["with_cast"], "1245")

        // Test discover with genres
        let genreEndpoint = TMDBEndpoint.discoverMovie(genres: [35, 12])
        let genreParams = genreEndpoint.extraQuery()
        XCTAssertEqual(genreParams?["with_genres"], "35,12")

        // Test discover with keywords
        let keywordEndpoint = TMDBEndpoint.discoverMovie(keywords: 9715)
        let keywordParams = keywordEndpoint.extraQuery()
        XCTAssertEqual(keywordParams?["with_keywords"], "9715")

        // Test discover with watch providers and region
        let providerEndpoint = TMDBEndpoint.discoverMovie(
            watchProviders: [8],
            watchRegion: "US"
        )
        let providerParams = providerEndpoint.extraQuery()
        XCTAssertEqual(providerParams?["with_watch_providers"], "8")
        XCTAssertEqual(providerParams?["watch_region"], "US")

        // Test comprehensive parameters
        let comprehensiveEndpoint = TMDBEndpoint.discoverMovie(
            keywords: 9715,
            cast: 1245,
            genres: [35],
            watchProviders: [8],
            watchRegion: "US",
            includeAdult: false,
            language: "en-US",
            page: 1
        )
        let comprehensiveParams = comprehensiveEndpoint.extraQuery()
        XCTAssertEqual(comprehensiveParams?["with_keywords"], "9715")
        XCTAssertEqual(comprehensiveParams?["with_cast"], "1245")
        XCTAssertEqual(comprehensiveParams?["with_genres"], "35")
        XCTAssertEqual(comprehensiveParams?["with_watch_providers"], "8")
        XCTAssertEqual(comprehensiveParams?["watch_region"], "US")
        XCTAssertEqual(comprehensiveParams?["include_adult"], "false")
        XCTAssertEqual(comprehensiveParams?["language"], "en-US")
        XCTAssertEqual(comprehensiveParams?["page"], "1")
    }
}