import Foundation

public protocol FavoriteServiceProtocol {
    func setFavoriteMovie(accountId: String, movieId: Int, favorite: Bool) async throws -> FavoriteResponse
    func setFavoriteTVShow(accountId: String, tvShowId: Int, favorite: Bool) async throws -> FavoriteResponse
    func getFavoriteMovies(accountId: String) async throws -> MovieListResultModel
    func getFavoriteTVShows(accountId: String) async throws -> TVShowListResultModel
}

public class FavoriteService: FavoriteServiceProtocol {
    private let apiService: TMDBAPIService

    public init(apiService: TMDBAPIService) {
        self.apiService = apiService
    }

    public func setFavoriteMovie(accountId: String, movieId: Int, favorite: Bool) async throws -> FavoriteResponse {
        return try await apiService.request(.setFavoriteMovie(accountId: accountId, movieId: movieId, favorite: favorite))
    }

    public func setFavoriteTVShow(accountId: String, tvShowId: Int, favorite: Bool) async throws -> FavoriteResponse {
        return try await apiService.request(.setFavoriteTVShow(accountId: accountId, tvShowId: tvShowId, favorite: favorite))
    }

    public func getFavoriteMovies(accountId: String) async throws -> MovieListResultModel {
        return try await apiService.request(.getFavoriteMovies(accountId: accountId))
    }

    public func getFavoriteTVShows(accountId: String) async throws -> TVShowListResultModel {
        return try await apiService.request(.getFavoriteTVShows(accountId: accountId))
    }
}