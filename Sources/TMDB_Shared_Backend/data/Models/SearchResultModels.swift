import Foundation

/// `search/collection` — franchises such as "The Lord of the Rings Collection".
public struct CollectionSearchResultModel: Codable {
    public let page: Int
    public let results: [MovieCollectionSummary]
    public let totalPages: Int
    public let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

public struct MovieCollectionSummary: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let overview: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let originalLanguage: String?
    public let originalName: String?

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case originalLanguage = "original_language"
        case originalName = "original_name"
    }
}

/// `search/company` — studios and production companies.
public struct CompanySearchResultModel: Codable {
    public let page: Int
    public let results: [CompanySummary]
    public let totalPages: Int
    public let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

public struct CompanySummary: Codable, Identifiable {
    public let id: Int
    public let name: String
    public let logoPath: String?
    public let originCountry: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case logoPath = "logo_path"
        case originCountry = "origin_country"
    }
}
