import TMDB_Shared_Backend
protocol APIServiceProtocol {
    func fetchNowPlayingMovies(page: Int?) async -> Result<NowPlayingResponse, Error>
    func searchMovies(query: String, page: Int?) async -> Result<NowPlayingResponse, Error>
}
extension TMDBAPIService: APIServiceProtocol {
    func fetchNowPlayingMovies(page: Int?) async -> Result<NowPlayingResponse, any Error> {
        let result: Result<NowPlayingResponse, TMDBAPIError> = await request(.nowPlaying(page: page))
        // Map TMDBAPIError to Error
        switch result {
        case .success(let response):
            return .success(response)
        case .failure(let error):
            return .failure(error as Error)
        }
    }
    
    func searchMovies(query: String, page: Int?) async -> Result<NowPlayingResponse, Error> {
        let result: Result<NowPlayingResponse, TMDBAPIError> = await request(.searchMovie(query: query, page: page))
        // Map TMDBAPIError to Error
        switch result {
        case .success(let response):
            return .success(response)
        case .failure(let error):
            return .failure(error as Error)
        }
    }
}
