@testable import TMDB_Dimilian_clean
// MARK: - Mock Classes

class MockFetchMoviesUseCase: FetchMoviesUseCase {
    var result: Result<[Movie], Error>!
    
    func execute() async -> Result<[Movie], Error> {
        return result
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
