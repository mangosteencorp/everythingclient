import XCTest
import SwiftUI
@testable import TMDB_clean_MLS

class MovieRowTests: XCTestCase {
    func testMovieRowInitialization() {
        let movie = Movie(id: 1, title: "Test Movie", overview: "Test Overview", posterPath: "/test.jpg", voteAverage: 7.5, popularity: 100.0, releaseDate: Date())
        let movieRow = MovieRow(movie: movie)
        
        XCTAssertNotNil(movieRow, "Should be able to initialize MovieRow")
        XCTAssertEqual(movieRow.movie.id, 1, "Movie ID should match")
        XCTAssertEqual(movieRow.movie.title, "Test Movie", "Movie title should match")
    }
    
    @available(iOS 15, *)
    func testMovieRowContent() {
        let movie = Movie(id: 1, title: "Test Movie", overview: "Test Overview", posterPath: "/test.jpg", voteAverage: 7.5, popularity: 100.0, releaseDate: Date())
        let movieRow = MovieRow(movie: movie)
        
        let rootView = movieRow.body
        
        // Check if the movie title is present
        let mirror = Mirror(reflecting: rootView)
        
        let text = findViewOfType(Text.self, in: rootView)
        XCTAssertNotNil(text, "View should contain a Text")
        
        if let textView = text {
            
            XCTAssertEqual(textView.string, movie.title, "View should contain a Text view with the movie title")
        }
        
    }
}
