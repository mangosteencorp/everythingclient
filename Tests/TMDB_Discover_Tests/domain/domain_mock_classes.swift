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

    func fetchNowPlayingMovies() async -> Result<[Movie], Error> {
        return result
    }

    func fetchUpcomingMovies() async -> Result<[Movie], Error> {
        return result
    }
}

enum MockError: Error {
    case noResponse
}
