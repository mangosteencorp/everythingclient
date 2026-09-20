import Tests_Shared_Helpers
@testable import TMDB_Person
import TMDB_Shared_Backend
import XCTest

final class PersonScorePointTests: XCTestCase {
    private func credit(id: Int, releaseDate: String?, voteAverage: Double, voteCount: Int) throws -> PersonMovieCredit {
        try JSONFixture.decode(from: """
        {
          "credit_id": "c\(id)", "id": \(id), "overview": "", "popularity": 1.0,
          "release_date": \(releaseDate.map { "\"\($0)\"" } ?? "null"), "title": "Movie \(id)",
          "vote_average": \(voteAverage), "vote_count": \(voteCount)
        }
        """)
    }

    func testPointsAreSortedByYearAndSkipBarelyRatedOrUndatedCredits() throws {
        let credits = try [
            credit(id: 1, releaseDate: "2019-05-01", voteAverage: 7.5, voteCount: 10),
            credit(id: 2, releaseDate: "1995-09-22", voteAverage: 8.4, voteCount: 1000),
            credit(id: 3, releaseDate: "2027-01-01", voteAverage: 0, voteCount: 0),
            credit(id: 4, releaseDate: nil, voteAverage: 6.0, voteCount: 50),
            credit(id: 5, releaseDate: "", voteAverage: 6.0, voteCount: 50),
            credit(id: 6, releaseDate: "2001-01-01", voteAverage: 10, voteCount: 1),
        ]

        XCTAssertEqual(PersonScorePoint.points(from: credits), [
            PersonScorePoint(id: 2, title: "Movie 2", year: 1995, score: 8.4),
            PersonScorePoint(id: 1, title: "Movie 1", year: 2019, score: 7.5),
        ])
    }
}
