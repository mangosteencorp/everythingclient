struct TVShowListResultModel: Codable {
    let page: Int
    let results: [TVShow]
    let total_pages: Int
    let total_results: Int
}

struct TVShow: Codable {
    let adult: Bool
    let backdrop_path: String?
    let genre_ids: [Int]
    let id: Int
    let origin_country: [String]
    let original_language: String
    let original_name: String
    let overview: String
    let popularity: Double
    let poster_path: String?
    let first_air_date: String
    let name: String
    let vote_average: Double
    let vote_count: Int
} 