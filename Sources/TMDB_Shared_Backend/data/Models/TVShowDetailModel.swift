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
    public let genres: [GenreModel]
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

// swiftlint:disable all
#if DEBUG
extension TVShowDetailModel {
    public static let example = TVShowDetailModel(
        id: 1399,
        name: "Game of Thrones",
        originalName: "Game of Thrones",
        overview: "Seven noble families fight for control of the mythical land of Westeros. Friction between the houses leads to full-scale war. All while a very ancient evil awakens in the farthest north. Amidst the war, a neglected military order of misfits, the Night's Watch, is all that stands between the realms of men and icy horrors beyond.",
        firstAirDate: "2011-04-17",
        lastAirDate: "2019-05-19",
        numberOfEpisodes: 73,
        numberOfSeasons: 8,
        voteAverage: 8.456,
        voteCount: 24515,
        status: "Ended",
        tagline: "Winter is coming.",
        type: "Scripted",
        posterPath: "/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg",
        backdropPath: "/zZqpAXxVSBtxV9qPBcscfXBcL2w.jpg",
        createdBy: [
            Creator(
                id: 9813,
                name: "David Benioff",
                gender: 2,
                profilePath: "/bOlW8pymCeQLfwPIvc2D1MRcUoF.jpg"
            ),
            Creator(
                id: 228068,
                name: "D. B. Weiss",
                gender: 2,
                profilePath: "/2RMejaT793U9KRk2IEbFfteQntE.jpg"
            ),
        ],
        genres: [
            GenreModel(id: 10765, name: "Sci-Fi & Fantasy"),
            GenreModel(id: 18, name: "Drama"),
            GenreModel(id: 10759, name: "Action & Adventure"),
        ],
        networks: [
            Network(
                id: 49,
                name: "HBO",
                originCountry: "US",
                logoPath: "/tuomPhY2UtuPTqqFnKMVHvSb724.png"
            ),
        ],
        seasons: [
            Season(
                id: 3624,
                name: "Season 1",
                overview: "Trouble is brewing in the Seven Kingdoms of Westeros...",
                airDate: "2011-04-17",
                episodeCount: 10,
                seasonNumber: 1,
                posterPath: "/wgfKiqzuMrFIkU1M68DDDY8kGC1.jpg",
                voteAverage: 8.3
            ),
            Season(
                id: 3625,
                name: "Season 2",
                overview: "The cold winds of winter are rising in Westeros...",
                airDate: "2012-04-01",
                episodeCount: 10,
                seasonNumber: 2,
                posterPath: "/9xfNkPwDOqyeUvfNhs1XlWA0esP.jpg",
                voteAverage: 8.3
            ),
        ]
    )
}
#endif
// swiftlint:enable all
