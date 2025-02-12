import Foundation

// swiftlint:disable identifier_name
public struct MovieDetailModel: Codable {
    public let adult: Bool
    public let backdrop_path: String?
    public let belongs_to_collection: Collection?
    public let budget: Int
    public let genres: [Genre]
    public let homepage: String?
    public let id: Int
    public let imdb_id: String?
    public let original_language: String
    public let original_title: String
    public let overview: String
    public let popularity: Double
    public let poster_path: String?
    public let production_companies: [ProductionCompany]
    public let production_countries: [ProductionCountry]
    public let release_date: String
    public let revenue: Int
    public let runtime: Int?
    public let spoken_languages: [SpokenLanguage]
    public let status: String
    public let tagline: String?
    public let title: String
    public let video: Bool
    public let vote_average: Double
    public let vote_count: Int
    public let keywords: KeywordResponse
    public let images: ImageResponse
}

public struct Genre: Codable {
    public let id: Int
    public let name: String
}

public struct Collection: Codable {
    public let id: Int
    public let name: String
    public let poster_path: String?
    public let backdrop_path: String?
}

public struct ProductionCompany: Codable {
    public let id: Int
    public let logo_path: String?
    public let name: String
    public let origin_country: String
}

public struct ProductionCountry: Codable {
    public let iso_3166_1: String
    public let name: String
}

public struct SpokenLanguage: Codable {
    public let english_name: String
    public let iso_639_1: String
    public let name: String
}

public struct KeywordResponse: Codable {
    public let keywords: [Keyword]
}

public struct Keyword: Codable {
    public let id: Int
    public let name: String
}

public struct ImageResponse: Codable {
    public let backdrops: [MovieImage]
    public let logos: [MovieImage]
    public let posters: [MovieImage]
}

public struct MovieImage: Codable {
    public let aspect_ratio: Double
    public let height: Int
    public let iso_639_1: String?
    public let file_path: String
    public let vote_average: Double
    public let vote_count: Int
    public let width: Int
}
// swiftlint:enable identifier_name