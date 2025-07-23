@testable import TMDB_Discover

// MARK: - Mock Classes

class MockFetchMoviesUseCase: FetchMoviesUseCase {
    var mockResult: Result<[Movie], Error>?

    func execute() async -> Result<[Movie], Error> {
        return mockResult ?? .failure(MockError.noResponse)
    }
}

class MockMovieRepository: MovieRepository {
    var result: Result<[Movie], Error>!
    var genresResult: Result<[Genre], Error>!
    var popularPeopleResult: Result<[PopularPerson], Error>!
    var trendingItemsResult: Result<[TrendingItem], Error>!

    func fetchNowPlayingMovies() async -> Result<[Movie], Error> {
        return result
    }

    func fetchUpcomingMovies() async -> Result<[Movie], Error> {
        return result
    }

    func fetchGenres() async -> Result<[Genre], Error> {
        return genresResult ?? .failure(MockError.noResponse)
    }

    func fetchPopularPeople() async -> Result<[PopularPerson], Error> {
        return popularPeopleResult ?? .failure(MockError.noResponse)
    }

    func fetchTrendingItems() async -> Result<[TrendingItem], Error> {
        return trendingItemsResult ?? .failure(MockError.noResponse)
    }
}

enum MockError: Error {
    case noResponse
}
