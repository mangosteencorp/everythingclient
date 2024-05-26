import Foundation
public struct MovieResponse: Codable {
    public let results: [Movie]
}

public struct Movie: Codable, Identifiable {
    public let id: Int
    public let title: String
    public let backdropPath: String
    public let genreIds: [Int]
    public let overview: String
    public let popularity: Double
    public let posterPath: ImagePath
    public let releaseDate: String
    public let voteAverage: Double
    public let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case id, title, overview, popularity, genreIds = "genre_ids"
        case backdropPath = "backdrop_path", posterPath = "poster_path"
        case releaseDate = "release_date", voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}

public typealias ImagePath = String
