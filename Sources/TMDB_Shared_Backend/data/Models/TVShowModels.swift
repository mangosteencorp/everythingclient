public struct TVShowListResultModel: Codable {
    public let page: Int
    public let results: [TVShow]
    public let total_pages: Int
    public let total_results: Int
}

public struct TVShow: Codable {
    public let adult: Bool
    public let backdrop_path: String?
    public let genre_ids: [Int]
    public let id: Int
    public let origin_country: [String]
    public let original_language: String
    public let original_name: String
    public let overview: String
    public let popularity: Double
    public let poster_path: String?
    public let first_air_date: String
    public let name: String
    public let vote_average: Double
    public let vote_count: Int
}
