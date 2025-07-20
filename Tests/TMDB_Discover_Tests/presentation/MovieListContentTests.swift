import SwiftUI
@testable import TMDB_Discover
import TMDB_Shared_UI
import ViewInspector
import XCTest

@available(iOS 16.0, *)
class MovieListContentTests: XCTestCase {
    func testMovieListContentInitialization() {
        // Given
        let movies = [
            Movie(
                id: 1,
                title: "Test Movie",
                overview: "Test Overview",
                posterPath: "/test.jpg",
                voteAverage: 7.5,
                popularity: 100.0,
                releaseDate: Movie.dateFormatter.date(from: "2024-01-01")
            ),
        ]

        // When
        let content = TVShowListContent(movies: movies, detailRouteBuilder: {_ in 1})

        // Then
        let mirror = Mirror(reflecting: content)
        guard let moviesProperty = mirror.children.first(where: { $0.label == "movies" })?.value as? [Movie] else {
            XCTFail("Movies property not found or wrong type")
            return
        }

        XCTAssertEqual(moviesProperty.count, 1)
        XCTAssertEqual(moviesProperty[0].id, movies[0].id)
        XCTAssertEqual(moviesProperty[0].title, movies[0].title)
        XCTAssertEqual(moviesProperty[0].overview, movies[0].overview)
        XCTAssertEqual(moviesProperty[0].posterPath, movies[0].posterPath)
        XCTAssertEqual(moviesProperty[0].voteAverage, movies[0].voteAverage)
        XCTAssertEqual(moviesProperty[0].popularity, movies[0].popularity)
        XCTAssertEqual(moviesProperty[0].releaseDate, movies[0].releaseDate)
    }

    func testListViewStructure() throws {
        let movie = Movie(
            id: 1,
            title: "Test Movie",
            overview: "Test Overview",
            posterPath: "/test.jpg",
            voteAverage: 7.5,
            popularity: 100.0,
            releaseDate: Movie.dateFormatter.date(from: "2024-01-01")
        )
        let content = TVShowListContent(movies: [movie], detailRouteBuilder: {_ in 1})

        // verify if there's a list and movie title displayed
        let _ = try content.inspect().find(viewWithAccessibilityIdentifier: "TVShowListContent.List")
        let _ = try content.inspect().find(text: "Test Movie")
    }
}
