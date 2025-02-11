import SwiftUI
import TMDB_MVVM_Detail

public struct MovieRouteModel: Hashable {
    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String?
    public let backdropPath: String?
    public let voteAverage: Float
    public let voteCount: Int
    public let releaseDate: String?
    public let popularity: Float?
    public let originalTitle: String?
    public init(id: Int,
                title: String,
                overview: String,
                posterPath: String?,
                backdropPath: String?,
                voteAverage: Float,
                voteCount: Int,
                releaseDate: String?,
                popularity: Float?,
                originalTitle: String?) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.releaseDate = releaseDate
        self.popularity = popularity
        self.originalTitle = originalTitle
    }
    public init(id: Int) {
        self.init(id: id, title: "", overview: "", posterPath: nil, backdropPath: nil, voteAverage: 0.0, voteCount: 0, releaseDate: nil, popularity: nil, originalTitle: nil)
    }
    func toMovieDetailModel() -> TMDB_MVVM_Detail.Movie {
        return TMDB_MVVM_Detail.Movie(id: self.id, original_title: self.originalTitle ?? "", title: self.title, overview: self.overview, poster_path: self.posterPath, backdrop_path: self.backdropPath, popularity: self.popularity ?? 0.0, vote_average: self.voteAverage, vote_count: self.voteCount, release_date: self.releaseDate, genres: nil, runtime: nil, status: nil, video: false)
    }
}
