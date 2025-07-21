import Foundation

// swiftlint:disable identifier_name
public struct PersonListResultModel: Codable {
    public let page: Int
    public let results: [PersonModel]
    public let totalPages: Int
    public let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

public struct PersonModel: Codable {
    public let adult: Bool
    public let gender: Int
    public let id: Int
    public let knownForDepartment: String
    public let name: String
    public let originalName: String
    public let popularity: Double
    public let profilePath: String?
    public let knownFor: [KnownForItem]

    enum CodingKeys: String, CodingKey {
        case adult, gender, id, name, popularity
        case knownForDepartment = "known_for_department"
        case originalName = "original_name"
        case profilePath = "profile_path"
        case knownFor = "known_for"
    }
}

public struct KnownForItem: Codable {
    public let adult: Bool
    public let backdropPath: String?
    public let id: Int
    public let title: String?
    public let originalTitle: String?
    public let name: String?
    public let originalName: String?
    public let overview: String
    public let posterPath: String?
    public let mediaType: String
    public let originalLanguage: String
    public let genreIds: [Int]
    public let popularity: Double
    public let releaseDate: String?
    public let firstAirDate: String?
    public let video: Bool?
    public let voteAverage: Double
    public let voteCount: Int
    public let originCountry: [String]?

    enum CodingKeys: String, CodingKey {
        case adult, id, overview, video
        case backdropPath = "backdrop_path"
        case title, name
        case originalTitle = "original_title"
        case originalName = "original_name"
        case posterPath = "poster_path"
        case mediaType = "media_type"
        case originalLanguage = "original_language"
        case genreIds = "genre_ids"
        case popularity
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case originCountry = "origin_country"
    }
}

// swiftlint:enable identifier_name