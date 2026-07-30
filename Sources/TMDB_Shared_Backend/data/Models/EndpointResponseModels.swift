import Foundation

public struct TMDBSuccessResponse: Codable {
    public let success: Bool
}

public struct KeywordSearchResultModel: Codable {
    public let page: Int
    public let results: [Keyword]
    public let totalPages: Int
    public let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

public struct MovieVideosResponse: Codable {
    public let id: Int
    public let results: [MovieVideo]
}

public struct MovieVideo: Codable, Identifiable {
    public let id: String
    public let key: String
    public let name: String
    public let official: Bool
    public let publishedAt: String
    public let site: String
    public let size: Int
    public let type: String

    enum CodingKeys: String, CodingKey {
        case id, key, name, official, site, size, type
        case publishedAt = "published_at"
    }
}

public struct MovieReviewsResponse: Codable {
    public let id: Int
    public let page: Int
    public let results: [MovieReview]
    public let totalPages: Int
    public let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case id, page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

public struct MovieReview: Codable, Identifiable {
    public let author: String
    public let content: String
    public let createdAt: String
    public let id: String
    public let updatedAt: String
    public let url: URL?

    enum CodingKeys: String, CodingKey {
        case author, content, id, url
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct PersonImagesResponse: Codable {
    public let id: Int
    public let profiles: [PersonImage]
}

public struct PersonImage: Codable {
    public let aspectRatio: Double
    public let filePath: String
    public let height: Int
    public let iso6391: String?
    public let voteAverage: Double
    public let voteCount: Int
    public let width: Int

    enum CodingKeys: String, CodingKey {
        case height, width
        case aspectRatio = "aspect_ratio"
        case filePath = "file_path"
        case iso6391 = "iso_639_1"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}
