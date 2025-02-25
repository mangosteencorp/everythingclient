import Foundation
public struct TVShowDetailModel: Codable {
    public let id: Int
    public let name: String
    public let originalName: String
    public let overview: String
    public let firstAirDate: String
    public let lastAirDate: String
    public let numberOfEpisodes: Int
    public let numberOfSeasons: Int
    public let voteAverage: Double
    public let voteCount: Int
    public let status: String
    public let tagline: String
    public let type: String
    public let posterPath: String?
    public let backdropPath: String?
    public let createdBy: [Creator]
    public let genres: [Genre]
    public let networks: [Network]
    public let seasons: [Season]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case originalName = "original_name"
        case overview
        case firstAirDate = "first_air_date"
        case lastAirDate = "last_air_date"
        case numberOfEpisodes = "number_of_episodes"
        case numberOfSeasons = "number_of_seasons"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case status
        case tagline
        case type
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case createdBy = "created_by"
        case genres
        case networks
        case seasons
    }
    
    public struct Creator: Codable {
        public let id: Int
        public let name: String
        public let gender: Int?
        public let profilePath: String?
        
        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case gender
            case profilePath = "profile_path"
        }
    }
    
    public struct Network: Codable {
        public let id: Int
        public let name: String
        public let originCountry: String
        public let logoPath: String?
        
        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case originCountry = "origin_country"
            case logoPath = "logo_path"
        }
    }
    
    public struct Season: Codable {
        public let id: Int
        public let name: String
        public let overview: String
        public let airDate: String?
        public let episodeCount: Int
        public let seasonNumber: Int
        public let posterPath: String?
        public let voteAverage: Double
        
        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case overview
            case airDate = "air_date"
            case episodeCount = "episode_count"
            case seasonNumber = "season_number"
            case posterPath = "poster_path"
            case voteAverage = "vote_average"
        }
    }
} 