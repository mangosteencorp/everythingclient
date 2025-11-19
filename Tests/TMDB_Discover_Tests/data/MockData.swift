import Foundation
@testable import TMDB_Discover
import TMDB_Shared_Backend

enum MockData {
    static let movieListResultModel: MovieListResultModel = decode(
        """
        {
            "dates": {
                "maximum": "2021-01-02",
                "minimum": "2021-01-01"
            },
            "page": 1,
            "results": [
                {
                    "id": 1,
                    "title": "Movie 1",
                    "overview": "Overview of Movie 1",
                    "poster_path": "/path1.jpg",
                    "vote_average": 7.5,
                    "popularity": 95.2,
                    "release_date": "2021-01-01",
                    "genre_ids": [28, 12]
                },
                {
                    "id": 2,
                    "title": "Movie 2",
                    "overview": "Overview of Movie 2",
                    "poster_path": "/path2.jpg",
                    "vote_average": 8.2,
                    "popularity": 88.3,
                    "release_date": null,
                    "genre_ids": [35]
                }
            ],
            "total_pages": 1,
            "total_results": 2
        }
        """,
        as: MovieListResultModel.self
    )

    static let tvShowListResultModel: TVShowListResultModel = decode(
        """
        {
            "page": 1,
            "results": [
                {
                    "adult": false,
                    "backdrop_path": "/backdrop1.jpg",
                    "genre_ids": [18, 9648],
                    "id": 101,
                    "origin_country": ["US"],
                    "original_language": "en",
                    "original_name": "Original Show 1",
                    "overview": "Overview of Show 1",
                    "popularity": 120.5,
                    "poster_path": "/poster1.jpg",
                    "first_air_date": "2021-01-01",
                    "name": "Show 1",
                    "vote_average": 7.5,
                    "vote_count": 200
                },
                {
                    "adult": false,
                    "backdrop_path": "/backdrop2.jpg",
                    "genre_ids": [35],
                    "id": 102,
                    "origin_country": ["US"],
                    "original_language": "en",
                    "original_name": "Original Show 2",
                    "overview": "Overview of Show 2",
                    "popularity": 110.1,
                    "poster_path": "/poster2.jpg",
                    "first_air_date": "2021-02-01",
                    "name": "Show 2",
                    "vote_average": 8.1,
                    "vote_count": 150
                }
            ],
            "total_pages": 1,
            "total_results": 2
        }
        """,
        as: TVShowListResultModel.self
    )

    private static func decode<T: Decodable>(_ json: String, as type: T.Type) -> T {
        guard let data = json.data(using: .utf8) else {
            fatalError("Failed to build data for \(T.self)")
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Failed to decode \(T.self): \(error)")
        }
    }
}
