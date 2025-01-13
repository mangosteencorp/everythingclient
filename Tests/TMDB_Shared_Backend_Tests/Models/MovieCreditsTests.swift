import XCTest
@testable import TMDB_Shared_Backend

final class MovieCreditsTests: XCTestCase {
    func testMovieCreditsEndpointBuilding() throws {
        let endpoint = TMDBEndpoint.credits(movie: 933260)
        
        XCTAssertEqual(endpoint.path(), "movie/933260/credits")
        XCTAssertEqual(endpoint.httpMethod(), .get)
        XCTAssertNil(endpoint.extraQuery())
    }
    
    func testMovieCreditsParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "credits", withExtension: "json"))
        let data = try XCTUnwrap(try Data(contentsOf: url))
        
        var credits: MovieCreditsModel?
        XCTAssertNoThrow(credits = try JSONDecoder().decode(MovieCreditsModel.self, from: data))
        
        let unwrappedCredits = try XCTUnwrap(credits)
        XCTAssertEqual(unwrappedCredits.id, 939243)
        
        let castMember = try XCTUnwrap(unwrappedCredits.cast.first)
        XCTAssertEqual(castMember.name, "Ben Schwartz")
        XCTAssertEqual(castMember.character, "Sonic (voice)")
        XCTAssertEqual(castMember.order, 0)
        
        let crewMember = try XCTUnwrap(unwrappedCredits.crew.first)
        XCTAssertEqual(crewMember.name, "Neal H. Moritz")
        XCTAssertEqual(crewMember.department, "Production")
        XCTAssertEqual(crewMember.job, "Producer")
    }
} 
