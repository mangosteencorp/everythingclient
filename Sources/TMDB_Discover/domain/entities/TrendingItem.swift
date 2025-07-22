import Foundation

public struct TrendingItem {
    public let id: Int
    public let title: String?
    public let name: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let overview: String?
    public let mediaType: String
    public let popularity: Double
    public let voteAverage: Double?
    
    public init(
        id: Int,
        title: String?,
        name: String?,
        posterPath: String?,
        backdropPath: String?,
        overview: String?,
        mediaType: String,
        popularity: Double,
        voteAverage: Double?
    ) {
        self.id = id
        self.title = title
        self.name = name
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.overview = overview
        self.mediaType = mediaType
        self.popularity = popularity
        self.voteAverage = voteAverage
    }
    
    public var displayTitle: String {
        return title ?? name ?? "Unknown"
    }
}