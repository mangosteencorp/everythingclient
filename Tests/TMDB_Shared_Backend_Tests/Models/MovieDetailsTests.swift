@testable import TMDB_Shared_Backend
import XCTest

final class MovieDetailsTests: XCTestCase {
    func testMovieDetailsParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "details", withExtension: "json"))
        let data = try XCTUnwrap(Data(contentsOf: url))

        var details: MovieDetailModel?
        XCTAssertNoThrow(details = try JSONDecoder().decode(MovieDetailModel.self, from: data))

        let unwrappedDetails = try XCTUnwrap(details)

        // Test basic movie information
        XCTAssertEqual(unwrappedDetails.id, 496_243)
        XCTAssertEqual(unwrappedDetails.title, "Parasite")
        XCTAssertEqual(unwrappedDetails.original_title, "기생충")
        XCTAssertEqual(unwrappedDetails.release_date, "2019-05-30")
        XCTAssertEqual(unwrappedDetails.vote_average, 8.5)
        XCTAssertEqual(unwrappedDetails.runtime, 133)

        // Test genres
        XCTAssertEqual(unwrappedDetails.genres.count, 3)
        XCTAssertEqual(unwrappedDetails.genres[0].name, "Comedy")
        XCTAssertEqual(unwrappedDetails.genres[1].name, "Thriller")
        XCTAssertEqual(unwrappedDetails.genres[2].name, "Drama")

        // Test production company
        let company = try XCTUnwrap(unwrappedDetails.production_companies.first)
        XCTAssertEqual(company.name, "Barunson E&A")
        XCTAssertEqual(company.origin_country, "KR")

        // Test spoken languages
        XCTAssertEqual(unwrappedDetails.spoken_languages.count, 3)
        XCTAssertEqual(unwrappedDetails.spoken_languages[0].english_name, "English")
        XCTAssertEqual(unwrappedDetails.spoken_languages[1].english_name, "German")
        XCTAssertEqual(unwrappedDetails.spoken_languages[2].english_name, "Korean")

        // Test keywords
        XCTAssertEqual(unwrappedDetails.keywords.keywords.count, 16)
        XCTAssertTrue(unwrappedDetails.keywords.keywords.contains(where: { $0.name == "dark comedy" }))

        // Test images
        XCTAssertEqual(unwrappedDetails.images.backdrops.count, 4)
        XCTAssertEqual(unwrappedDetails.images.logos.count, 3)
        let firstBackdrop = try XCTUnwrap(unwrappedDetails.images.backdrops.first)
        XCTAssertEqual(firstBackdrop.file_path, "/gf1cTS5rYIgGDMvqjPZaTbD3Ycy.jpg")
    }
}
