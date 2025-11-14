@testable import TMDB_Discover

// MARK: - Mock Classes

class MockFetchMoviesUseCase: FetchMoviesUseCase {
    var mockResult: Result<[Movie], Error>?

    func execute() async -> Result<[Movie], Error> {
        return mockResult ?? .failure(MockError.noResponse)
    }
}

class MockMovieRepository: DiscoverRepository {
    var result: Result<[Movie], Error>!
    var genresResult: Result<[Genre], Error>!
    var tvGenresResult: Result<[Genre], Error>?
    var popularPeopleResult: Result<[PopularPerson], Error>!
    var trendingItemsResult: Result<[TrendingItem], Error>!
    var toggleFavoriteResult: Result<Bool, Error>?
    var favoriteTVShowsResult: Result<[Int], Error>?
    var discoverMoviesResult: Result<[Movie], Error>?
    var discoverTVResult: Result<[Movie], Error>?

    func fetchNowPlayingMovies() async -> Result<[Movie], Error> {
        return result
    }

    func fetchUpcomingMovies() async -> Result<[Movie], Error> {
        return result
    }

    func fetchGenres() async -> Result<[Genre], Error> {
        return genresResult ?? .failure(MockError.noResponse)
    }

    func fetchTVGenres() async -> Result<[Genre], Error> {
        return tvGenresResult ?? .failure(MockError.noResponse)
    }

    func fetchPopularPeople() async -> Result<[PopularPerson], Error> {
        return popularPeopleResult ?? .failure(MockError.noResponse)
    }

    func fetchTrendingItems() async -> Result<[TrendingItem], Error> {
        return trendingItemsResult ?? .failure(MockError.noResponse)
    }

    func toggleTVShowFavorite(tvShowId: Int, isFavorite: Bool) async -> Result<Bool, Error> {
        return toggleFavoriteResult ?? .success(isFavorite)
    }

    func fetchFavoriteTVShows() async -> Result<[Int], Error> {
        return favoriteTVShowsResult ?? .failure(MockError.noResponse)
    }

    func discoverMovies(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        page: Int?,
        mediaType: DiscoverMediaType
    ) async -> Result<[Movie], Error> {
        return discoverMoviesResult ?? result ?? .failure(MockError.noResponse)
    }

    func discoverTV(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        page: Int?
    ) async -> Result<[Movie], Error> {
        return discoverTVResult ?? .failure(MockError.noResponse)
    }
}

enum MockError: Error {
    case noResponse
}
