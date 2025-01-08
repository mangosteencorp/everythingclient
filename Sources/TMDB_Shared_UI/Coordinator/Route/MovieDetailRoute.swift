import SwiftUI
// MARK: - MovieDetailRoute.swift
public struct MovieDetailRoute: Route {
    public let movie: MovieRouteModel
    public init(movie: MovieRouteModel) {
        self.movie = movie
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(movie.id)
    }
    
    public static func == (lhs: MovieDetailRoute, rhs: MovieDetailRoute) -> Bool {
        lhs.movie.id == rhs.movie.id
    }
}

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
    
}
