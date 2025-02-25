@testable import TMDB_Shared_Backend
import XCTest

final class TVShowDetailsTests: XCTestCase {
    func testTVShowDetailsEndpointBuilding() throws {
        let endpoint = TMDBEndpoint.tvShowDetail(show: 1399)
        
        XCTAssertEqual(endpoint.path(), "tv/1399")
        XCTAssertEqual(endpoint.httpMethod(), .get)
        XCTAssertNil(endpoint.extraQuery())
    }
    
    func testTVShowDetailsParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "tv_details", withExtension: "json"))
        let data = try XCTUnwrap(Data(contentsOf: url))
        
        var details: TVShowDetailModel?
        XCTAssertNoThrow(details = try JSONDecoder().decode(TVShowDetailModel.self, from: data))
        
        let unwrappedDetails = try XCTUnwrap(details)
        
        // Test basic show information
        XCTAssertEqual(unwrappedDetails.id, 1399)
        XCTAssertEqual(unwrappedDetails.name, "Game of Thrones")
        XCTAssertEqual(unwrappedDetails.originalName, "Game of Thrones")
        XCTAssertEqual(unwrappedDetails.firstAirDate, "2011-04-17")
        XCTAssertEqual(unwrappedDetails.lastAirDate, "2019-05-19")
        XCTAssertEqual(unwrappedDetails.numberOfEpisodes, 73)
        XCTAssertEqual(unwrappedDetails.numberOfSeasons, 8)
        XCTAssertEqual(unwrappedDetails.voteAverage, 8.456)
        XCTAssertEqual(unwrappedDetails.status, "Ended")
        XCTAssertEqual(unwrappedDetails.tagline, "Winter is coming.")
        
        // Test creators
        XCTAssertEqual(unwrappedDetails.createdBy.count, 2)
        let firstCreator = try XCTUnwrap(unwrappedDetails.createdBy.first)
        XCTAssertEqual(firstCreator.name, "David Benioff")
        XCTAssertEqual(firstCreator.id, 9813)
        
        // Test genres
        XCTAssertEqual(unwrappedDetails.genres.count, 3)
        XCTAssertTrue(unwrappedDetails.genres.contains(where: { $0.name == "Drama" }))
        
        // Test networks
        XCTAssertEqual(unwrappedDetails.networks.count, 1)
        let network = try XCTUnwrap(unwrappedDetails.networks.first)
        XCTAssertEqual(network.name, "HBO")
        XCTAssertEqual(network.originCountry, "US")
        
        // Test seasons
        XCTAssertEqual(unwrappedDetails.seasons.count, 9) // Including specials
        let season1 = try XCTUnwrap(unwrappedDetails.seasons.first { $0.seasonNumber == 1 })
        XCTAssertEqual(season1.episodeCount, 10)
        XCTAssertEqual(season1.name, "Season 1")
        XCTAssertEqual(season1.voteAverage, 8.3)
    }
} 