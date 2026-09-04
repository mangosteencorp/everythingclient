// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
public enum DiscoverMediaType {
    case movie
    case tv
}

public struct DiscoverMoviesParams {
    public let keywords: Int?
    public let cast: Int?
    public let genres: [Int]?
    public let watchProviders: [Int]?
    public let watchRegion: String?
    public let page: Int?
    public let mediaType: DiscoverMediaType

    public init(
        keywords: Int? = nil,
        cast: Int? = nil,
        genres: [Int]? = nil,
        watchProviders: [Int]? = nil,
        watchRegion: String? = nil,
        page: Int? = nil,
        mediaType: DiscoverMediaType = .movie
    ) {
        self.keywords = keywords
        self.cast = cast
        self.genres = genres
        self.watchProviders = watchProviders
        self.watchRegion = watchRegion
        self.page = page
        self.mediaType = mediaType
    }
}

protocol FetchDiscoverMoviesUseCase {
    func execute(params: DiscoverMoviesParams) async -> Result<[Movie], Error>
}

class DefaultFetchDiscoverMoviesUseCase: FetchDiscoverMoviesUseCase {
    private let movieRepository: DiscoverRepository

    public init(movieRepository: DiscoverRepository) {
        self.movieRepository = movieRepository
    }

    public func execute(params: DiscoverMoviesParams) async -> Result<[Movie], Error> {
        switch params.mediaType {
        case .movie:
            return await movieRepository.discoverMovies(
                keywords: params.keywords,
                cast: params.cast,
                genres: params.genres,
                watchProviders: params.watchProviders,
                watchRegion: params.watchRegion,
                page: params.page,
                mediaType: params.mediaType
            )
        case .tv:
            return await movieRepository.discoverTV(
                keywords: params.keywords,
                cast: params.cast,
                genres: params.genres,
                watchProviders: params.watchProviders,
                watchRegion: params.watchRegion,
                page: params.page
            )
        }
    }
}
#endif
