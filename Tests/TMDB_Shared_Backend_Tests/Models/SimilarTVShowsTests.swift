@testable import TMDB_Shared_Backend
import XCTest

final class SimilarTVShowsTests: XCTestCase {
    func testSimilarTVShowsEndpointBuilding() throws {
        let endpoint = TMDBEndpoint.similarTVShows(show: 1399)

        XCTAssertEqual(endpoint.path(), "tv/1399/similar")
        XCTAssertEqual(endpoint.httpMethod(), .get)
        XCTAssertNil(endpoint.extraQuery())
        XCTAssertTrue(try endpoint.returnType() == TVShowListResultModel.self)
    }

    func testSimilarTVShowsEndpointBuildingWithPage() throws {
        let endpoint = TMDBEndpoint.similarTVShows(show: 1399, page: 1)

        XCTAssertEqual(endpoint.path(), "tv/1399/similar")
        XCTAssertEqual(endpoint.extraQuery()?["page"], "1")
    }

    func testSimilarTVShowsParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "tv_similar", withExtension: "json"))
        let data = try XCTUnwrap(Data(contentsOf: url))

        var similarShows: TVShowListResultModel?
        XCTAssertNoThrow(similarShows = try JSONDecoder().decode(TVShowListResultModel.self, from: data))

        let unwrappedShows = try XCTUnwrap(similarShows)
        XCTAssertEqual(unwrappedShows.page, 1)
        XCTAssertEqual(unwrappedShows.total_pages, 82)
        XCTAssertEqual(unwrappedShows.total_results, 1639)
        XCTAssertEqual(unwrappedShows.results.count, 20)

        let firstShow = try XCTUnwrap(unwrappedShows.results.first)
        XCTAssertEqual(firstShow.name, "Pale Moon")
        XCTAssertEqual(firstShow.original_name, "종이달")
        XCTAssertEqual(firstShow.id, 197_063)
        XCTAssertEqual(firstShow.first_air_date, "2023-04-10")
        XCTAssertEqual(firstShow.vote_average, 7)
        XCTAssertEqual(firstShow.origin_country, ["KR"])
        XCTAssertEqual(firstShow.poster_path, "/xXWynVdMGyJXBUDvIN27AXM3iJJ.jpg")

        let showWithoutPoster = try XCTUnwrap(unwrappedShows.results.first { $0.id == 197_123 })
        XCTAssertEqual(showWithoutPoster.name, "The White Darkness")
        XCTAssertEqual(showWithoutPoster.first_air_date, "")
        XCTAssertNil(showWithoutPoster.poster_path)
        XCTAssertNil(showWithoutPoster.backdrop_path)
    }
}
