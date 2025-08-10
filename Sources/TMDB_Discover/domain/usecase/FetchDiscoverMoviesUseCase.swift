public struct DiscoverMoviesParams {
    public let keywords: Int?
    public let cast: Int?
    public let genres: [Int]?
    public let watchProviders: [Int]?
    public let watchRegion: String?
    public let page: Int?

    public init(
        keywords: Int? = nil,
        cast: Int? = nil,
        genres: [Int]? = nil,
        watchProviders: [Int]? = nil,
        watchRegion: String? = nil,
        page: Int? = nil
    ) {
        self.keywords = keywords
        self.cast = cast
        self.genres = genres
        self.watchProviders = watchProviders
        self.watchRegion = watchRegion
        self.page = page
    }
}

protocol FetchDiscoverMoviesUseCase {
    func execute(params: DiscoverMoviesParams) async -> Result<[Movie], Error>
}

class DefaultFetchDiscoverMoviesUseCase: FetchDiscoverMoviesUseCase {
    private let movieRepository: MovieRepository

    public init(movieRepository: MovieRepository) {
        self.movieRepository = movieRepository
    }

    public func execute(params: DiscoverMoviesParams) async -> Result<[Movie], Error> {
        return await movieRepository.discoverMovies(
            keywords: params.keywords,
            cast: params.cast,
            genres: params.genres,
            watchProviders: params.watchProviders,
            watchRegion: params.watchRegion,
            page: params.page
        )
    }
}
