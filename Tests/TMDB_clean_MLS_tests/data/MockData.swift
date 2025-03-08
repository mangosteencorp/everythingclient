import Foundation
@testable import TMDB_clean_MLS

enum MockData {
    static let movies: [APIMovie] = [
        APIMovie(
            id: 1,
            title: "Movie 1",
            overview: "Overview of Movie 1",
            poster_path: "/path1.jpg",
            vote_average: 7.5,
            popularity: 95.2,
            release_date: "2021-01-01"
        ),
        APIMovie(
            id: 2,
            title: "Movie 2",
            overview: "Overview of Movie 2",
            poster_path: "/path2.jpg",
            vote_average: 8.2,
            popularity: 88.3,
            release_date: nil
        ),
    ]

    static let movieListResultModel = MovieListResultModel(
        dates: Dates(maximum: "2021-01-02", minimum: "2021-01-01"),
        page: 1,
        results: movies,
        totalPages: 1,
        totalResults: movies.count
    )
}
