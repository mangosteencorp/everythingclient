import Foundation

public struct Movie: Codable, Identifiable {
    public let id: Int

    let originalTitle: String
    let title: String
    var userTitle: String {
        return originalTitle
    }

    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let popularity: Float
    let voteAverage: Float
    let voteCount: Int

    let releaseDate: String?
    var releaseDateFormatted: Date? {
        return Movie.dateFormatter.date(from: releaseDate ?? "")
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyy-MM-dd"
        return formatter
    }()

    let genres: [Genre]?
    let runtime: Int?
    let status: String?
    let video: Bool

    var keywords: Keywords?
    var images: MovieImages?

    var productionCountries: [ProductionCountry]?

    var character: String?
    var department: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, overview, popularity, video
        case originalTitle = "original_title"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case releaseDate = "release_date"
        case genres, runtime, status
        case keywords, images
        case productionCountries = "production_countries"
        case character, department
    }

    public struct Keywords: Codable {
        let keywords: [Keyword]?
    }

    public struct MovieImages: Codable {
        let posters: [ImageData]?
        let backdrops: [ImageData]?
    }

    public struct ProductionCountry: Codable, Identifiable {
        public var id: String {
            name
        }

        let name: String
    }

    static func placeholder(id: Int) -> Movie {
        // swiftlint:disable line_length
        return Movie(
            id: id,
            originalTitle: "",
            title: "",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            popularity: 0.0,
            voteAverage: 0.0,
            voteCount: 0,
            releaseDate: nil,
            genres: nil,
            runtime: nil,
            status: nil,
            video: false
        )
        // swiftlint:enable line_length
    }

    public init(
        id: Int,
        originalTitle: String,
        title: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        popularity: Float,
        voteAverage: Float,
        voteCount: Int,
        releaseDate: String?,
        genres: [Genre]?,
        runtime: Int?,
        status: String?,
        video: Bool,
        keywords: Keywords? = nil,
        images: MovieImages? = nil,
        productionCountries: [ProductionCountry]? = nil,
        character: String? = nil,
        department: String? = nil
    ) {
        self.id = id
        self.originalTitle = originalTitle
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.popularity = popularity
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.releaseDate = releaseDate
        self.genres = genres
        self.runtime = runtime
        self.status = status
        self.video = video
        self.keywords = keywords
        self.images = images
        self.productionCountries = productionCountries
        self.character = character
        self.department = department
    }
}
