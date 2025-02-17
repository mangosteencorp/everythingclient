import TMDB_Shared_Backend

public struct AdditionalMovieListParams: Hashable {
    public let keywordId: Int?

    public static func keyword(_ id: Int) -> AdditionalMovieListParams {
        AdditionalMovieListParams(keywordId: id)
    }

    public static let none = AdditionalMovieListParams(keywordId: nil)
}

public protocol APIServiceProtocol {
    // Required methods with all parameters
    func fetchNowPlayingMovies(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<NowPlayingResponse, Error>
    func searchMovies(query: String, page: Int?) async -> Result<NowPlayingResponse, Error>
}

// Optional convenience methods
public extension APIServiceProtocol {
    func fetchNowPlayingMovies() async -> Result<NowPlayingResponse, Error> {
        await fetchNowPlayingMovies(page: nil, additionalParams: nil)
    }

    func searchMovies(query: String) async -> Result<NowPlayingResponse, Error> {
        await searchMovies(query: query, page: nil)
    }
}

extension TMDBAPIService: APIServiceProtocol {
    public func fetchNowPlayingMovies(page: Int?, additionalParams: AdditionalMovieListParams? = nil) async -> Result<NowPlayingResponse, any Error> {
        let result: Result<NowPlayingResponse, TMDBAPIError> = await {
            if let params = additionalParams, let keywordId = params.keywordId {
                return await request(.discoverMovie(keywords: keywordId, page: page))
            }
            return await request(.nowPlaying(page: page))
        }()
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
