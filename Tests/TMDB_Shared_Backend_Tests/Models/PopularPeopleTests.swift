@testable import TMDB_Shared_Backend
import XCTest

final class PopularPeopleTests: XCTestCase {
    func testPopularPeopleParsing() throws {
        let bundle = Bundle.module
        let url = try XCTUnwrap(bundle.url(forResource: "people_popular", withExtension: "json"))
        let data = try XCTUnwrap(Data(contentsOf: url))

        var peopleList: PersonListResultModel?
        XCTAssertNoThrow(peopleList = try JSONDecoder().decode(PersonListResultModel.self, from: data))

        let unwrappedPeopleList = try XCTUnwrap(peopleList)

        // Test pagination info
        XCTAssertEqual(unwrappedPeopleList.page, 1)
        XCTAssertEqual(unwrappedPeopleList.totalPages, 206283)
        XCTAssertEqual(unwrappedPeopleList.totalResults, 4125658)

        // Test that we have results
        XCTAssertGreaterThan(unwrappedPeopleList.results.count, 0)

        // Test first person (Scarlett Johansson)
        let firstPerson = try XCTUnwrap(unwrappedPeopleList.results.first)
        XCTAssertEqual(firstPerson.id, 1245)
        XCTAssertEqual(firstPerson.name, "Scarlett Johansson")
        XCTAssertEqual(firstPerson.originalName, "Scarlett Johansson")
        XCTAssertEqual(firstPerson.gender, 1)
        XCTAssertEqual(firstPerson.knownForDepartment, "Acting")
        XCTAssertEqual(firstPerson.popularity, 24.3683, accuracy: 0.0001)
        XCTAssertEqual(firstPerson.profilePath, "/8m21eocprLYuW0ywveIgThk6VM.jpg")

        // Test known for items
        XCTAssertGreaterThan(firstPerson.knownFor.count, 0)
        let firstKnownFor = try XCTUnwrap(firstPerson.knownFor.first)
        XCTAssertEqual(firstKnownFor.id, 240832)
        XCTAssertEqual(firstKnownFor.title, "Lucy")
        XCTAssertEqual(firstKnownFor.originalTitle, "Lucy")
        XCTAssertEqual(firstKnownFor.mediaType, "movie")
        XCTAssertEqual(firstKnownFor.originalLanguage, "en")
        XCTAssertEqual(firstKnownFor.popularity, 15.8372, accuracy: 0.0001)
        XCTAssertEqual(firstKnownFor.voteAverage, 6.465, accuracy: 0.001)
        XCTAssertEqual(firstKnownFor.voteCount, 16387)

        // Test second person (Sandra Bullock)
        let secondPerson = try XCTUnwrap(unwrappedPeopleList.results.dropFirst().first)
        XCTAssertEqual(secondPerson.id, 18277)
        XCTAssertEqual(secondPerson.name, "Sandra Bullock")
        XCTAssertEqual(secondPerson.originalName, "Sandra Bullock")
    }
}