import TMDB_Shared_Backend

public protocol APIServiceProtocol {
    func fetchNowPlayingMovies(page: Int?) async -> Result<NowPlayingResponse, Error>
    func searchMovies(query: String, page: Int?) async -> Result<NowPlayingResponse, Error>
}

extension TMDBAPIService: APIServiceProtocol {
    public func fetchNowPlayingMovies(page: Int?) async -> Result<NowPlayingResponse, any Error> {
        let result: Result<NowPlayingResponse, TMDBAPIError> = await request(.nowPlaying(page: page))
        // Map TMDBAPIError to Error
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    public func searchMovies(query: String, page: Int?) async -> Result<NowPlayingResponse, Error> {
        let result: Result<NowPlayingResponse, TMDBAPIError> = await request(.searchMovie(query: query, page: page))
        // Map TMDBAPIError to Error
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }
}
