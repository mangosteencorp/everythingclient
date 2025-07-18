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
    func fetchNowPlayingMovies(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<MovieListResponse, Error>
    func fetchPopularMovies(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<MovieListResponse, Error>
    func fetchTopRatedMovies(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<MovieListResponse, Error>
    func fetchUpcomingMovies(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<MovieListResponse, Error>
    func searchMovies(query: String, page: Int?) async -> Result<MovieListResponse, Error>
    func searchMovies(query: String, page: Int?, filters: SearchFilters?) async -> Result<MovieListResponse, Error>

    // TV Show methods
    func fetchAiringTodayTVShows(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<TVShowListResponse, Error>
    func fetchOnTheAirTVShows(page: Int?, additionalParams: AdditionalMovieListParams?) async -> Result<TVShowListResponse, Error>
    func searchTVShows(query: String, page: Int?) async -> Result<TVShowListResponse, Error>
    func searchTVShows(query: String, page: Int?, filters: SearchFilters?) async -> Result<TVShowListResponse, Error>
}

// Optional convenience methods
public extension APIServiceProtocol {
    func fetchNowPlayingMovies() async -> Result<MovieListResponse, Error> {
        await fetchNowPlayingMovies(page: nil, additionalParams: nil)
    }

    func fetchPopularMovies() async -> Result<MovieListResponse, Error> {
        await fetchPopularMovies(page: nil, additionalParams: nil)
    }

    func fetchTopRatedMovies() async -> Result<MovieListResponse, Error> {
        await fetchTopRatedMovies(page: nil, additionalParams: nil)
    }

    func fetchUpcomingMovies() async -> Result<MovieListResponse, Error> {
        await fetchUpcomingMovies(page: nil, additionalParams: nil)
    }

    func searchMovies(query: String) async -> Result<MovieListResponse, Error> {
        await searchMovies(query: query, page: nil)
    }

    func searchMovies(query: String, filters: SearchFilters?) async -> Result<MovieListResponse, Error> {
        await searchMovies(query: query, page: nil, filters: filters)
    }

    func fetchAiringTodayTVShows(page: Int? = nil) async -> Result<TVShowListResponse, Error> {
        return await fetchAiringTodayTVShows(page: page, additionalParams: nil)
    }

    func fetchOnTheAirTVShows(page: Int? = nil) async -> Result<TVShowListResponse, Error> {
        return await fetchOnTheAirTVShows(page: page, additionalParams: nil)
    }

    func searchTVShows(query: String) async -> Result<TVShowListResponse, Error> {
        return await searchTVShows(query: query, page: nil)
    }
}

extension TMDBAPIService: APIServiceProtocol {
    public func fetchNowPlayingMovies(page: Int?, additionalParams: AdditionalMovieListParams? = nil) async -> Result<MovieListResponse, any Error> {
        let result: Result<MovieListResponse, TMDBAPIError> = await {
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

    public func fetchPopularMovies(page: Int?, additionalParams: AdditionalMovieListParams? = nil) async -> Result<MovieListResponse, any Error> {
        let result: Result<MovieListResponse, TMDBAPIError> = await {
            if let params = additionalParams, let keywordId = params.keywordId {
                return await request(.discoverMovie(keywords: keywordId, page: page))
            }
            return await request(.popular(page: page))
        }()
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    public func fetchTopRatedMovies(page: Int?, additionalParams: AdditionalMovieListParams? = nil) async -> Result<MovieListResponse, any Error> {
        let result: Result<MovieListResponse, TMDBAPIError> = await {
            if let params = additionalParams, let keywordId = params.keywordId {
                return await request(.discoverMovie(keywords: keywordId, page: page))
            }
            return await request(.topRated(page: page))
        }()
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    public func fetchUpcomingMovies(page: Int?, additionalParams: AdditionalMovieListParams? = nil) async -> Result<MovieListResponse, any Error> {
        let result: Result<MovieListResponse, TMDBAPIError> = await {
            if let params = additionalParams, let keywordId = params.keywordId {
                return await request(.discoverMovie(keywords: keywordId, page: page))
            }
            return await request(.upcoming(page: page))
        }()
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    public func searchMovies(query: String, page: Int?) async -> Result<MovieListResponse, Error> {
        let result: Result<MovieListResponse, TMDBAPIError> = await request(.searchMovie(query: query, page: page))
        // Map TMDBAPIError to Error
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    public func searchMovies(query: String, page: Int?, filters: SearchFilters?) async -> Result<MovieListResponse, Error> {
        let result: Result<MovieListResponse, TMDBAPIError> = await request(.searchMovie(
            query: query,
            includeAdult: filters?.includeAdult,
            language: filters?.language,
            primaryReleaseYear: filters?.primaryReleaseYear,
            page: page,
            region: filters?.region,
            year: filters?.year
        ))
        // Map TMDBAPIError to Error
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    public func fetchAiringTodayTVShows(page: Int?, additionalParams: AdditionalMovieListParams? = nil) async -> Result<TVShowListResponse, Error> {
        let result: Result<TVShowListResultModel, TMDBAPIError> = await request(.tvAiringToday(page: page))
        // Map TMDBAPIError to Error and convert response type
        switch result {
        case let .success(response):
            let tvShowResponse = TVShowListResponse(
                page: response.page,
                results: response.results,
                totalPages: response.total_pages,
                totalResults: response.total_results
            )
            return .success(tvShowResponse)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    public func fetchOnTheAirTVShows(page: Int?, additionalParams: AdditionalMovieListParams? = nil) async -> Result<TVShowListResponse, Error> {
        let result: Result<TVShowListResultModel, TMDBAPIError> = await request(.tvOnTheAir(page: page))
        // Map TMDBAPIError to Error and convert response type
        switch result {
        case let .success(response):
            let tvShowResponse = TVShowListResponse(
                page: response.page,
                results: response.results,
                totalPages: response.total_pages,
                totalResults: response.total_results
            )
            return .success(tvShowResponse)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    public func searchTVShows(query: String, page: Int?) async -> Result<TVShowListResponse, Error> {
        let result: Result<TVShowListResultModel, TMDBAPIError> = await request(.searchTVShows(query: query, page: page))
        // Map TMDBAPIError to Error and convert response type
        switch result {
        case let .success(response):
            let tvShowResponse = TVShowListResponse(
                page: response.page,
                results: response.results,
                totalPages: response.total_pages,
                totalResults: response.total_results
            )
            return .success(tvShowResponse)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    public func searchTVShows(query: String, page: Int?, filters: SearchFilters?) async -> Result<TVShowListResponse, Error> {
        let result: Result<TVShowListResultModel, TMDBAPIError> = await request(.searchTVShows(
            query: query,
            includeAdult: filters?.includeAdult,
            language: filters?.language,
            firstAirDateYear: filters?.primaryReleaseYear,
            page: page,
            region: filters?.region,
            year: filters?.year
        ))
        // Map TMDBAPIError to Error and convert response type
        switch result {
        case let .success(response):
            let tvShowResponse = TVShowListResponse(
                page: response.page,
                results: response.results,
                totalPages: response.total_pages,
                totalResults: response.total_results
            )
            return .success(tvShowResponse)
        case let .failure(error):
            return .failure(error as Error)
        }
    }
}
