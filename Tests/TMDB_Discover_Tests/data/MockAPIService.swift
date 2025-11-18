@testable import TMDB_Discover
import TMDB_Shared_Backend

final class MockAPIService: APIServiceProtocol {
    var fetchGenresResult: Result<GenreListModel, Error>?
    var fetchTVGenresResult: Result<GenreListModel, Error>?
    var fetchPopularPeopleResult: Result<PersonListResultModel, Error>?
    var fetchTrendingItemsResult: Result<TrendingAllResultModel, Error>?
    var toggleFavoriteResult: Result<Bool, Error>?
    var fetchFavoriteTVShowsResult: Result<TVShowListResultModel, Error>?
    var discoverMoviesResult: Result<MovieListResultModel, Error>?
    var discoverTVResult: Result<TVShowListResultModel, Error>?

    func fetchGenres() async -> Result<GenreListModel, Error> {
        fetchGenresResult ?? .failure(MockError.noResponse)
    }

    func fetchTVGenres() async -> Result<GenreListModel, Error> {
        fetchTVGenresResult ?? .failure(MockError.noResponse)
    }

    func fetchPopularPeople() async -> Result<PersonListResultModel, Error> {
        fetchPopularPeopleResult ?? .failure(MockError.noResponse)
    }

    func fetchTrendingItems() async -> Result<TrendingAllResultModel, Error> {
        fetchTrendingItemsResult ?? .failure(MockError.noResponse)
    }

    func toggleTVShowFavorite(tvShowId: Int, isFavorite: Bool) async -> Result<Bool, Error> {
        toggleFavoriteResult ?? .failure(MockError.noResponse)
    }

    func fetchFavoriteTVShows() async -> Result<TVShowListResultModel, Error> {
        fetchFavoriteTVShowsResult ?? .failure(MockError.noResponse)
    }

    func discoverMovies(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        page: Int?,
        mediaType: DiscoverMediaType
    ) async -> Result<MovieListResultModel, Error> {
        discoverMoviesResult ?? .failure(MockError.noResponse)
    }

    func discoverTV(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        page: Int?
    ) async -> Result<TVShowListResultModel, Error> {
        discoverTVResult ?? .failure(MockError.noResponse)
    }
}
