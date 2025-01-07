import SwiftUI
// MARK: - MovieDetailRoute.swift
public struct MovieDetailRoute: Route {
    let movie: MovieRouteModel
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(movie.id)
    }
    
    public static func == (lhs: MovieDetailRoute, rhs: MovieDetailRoute) -> Bool {
        lhs.movie.id == rhs.movie.id
    }
}

struct MovieRouteModel: Hashable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Float
    let voteCount: Int
    let releaseDate: String?
    
    init(id: Int,
         title: String,
         overview: String,
         posterPath: String?,
         backdropPath: String?,
         voteAverage: Float,
         voteCount: Int,
         releaseDate: String?) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.releaseDate = releaseDate
    }
    
}
