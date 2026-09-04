// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
import TMDB_Shared_Backend

extension TMDBAPIService: APIServiceProtocol {
    func fetchGenres() async -> Result<GenreListModel, Error> {
        let result: Result<GenreListModel, TMDBAPIError> = await request(.genres)
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    func fetchTVGenres() async -> Result<GenreListModel, Error> {
        let result: Result<GenreListModel, TMDBAPIError> = await request(.tvGenres)
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    func fetchPopularPeople() async -> Result<PersonListResultModel, Error> {
        let result: Result<PersonListResultModel, TMDBAPIError> = await request(.popularPersons)
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    func fetchTrendingItems() async -> Result<TrendingAllResultModel, Error> {
        let result: Result<TrendingAllResultModel, TMDBAPIError> = await request(.trendingAll())
        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    func toggleTVShowFavorite(tvShowId: Int, isFavorite: Bool) async -> Result<Bool, Error> {
        // First get account info
        let accountResult: Result<AccountInfoModel, TMDBAPIError> = await request(.accountInfo)

        switch accountResult {
        case let .success(accountInfo):
            let accountId = String(accountInfo.id)
            let favoriteResult: Result<FavoriteResponse, TMDBAPIError> = await request(
                .setFavoriteTVShow(accountId: accountId, tvShowId: tvShowId, favorite: isFavorite)
            )

            switch favoriteResult {
            case let .success(response):
                return .success(response.success)
            case let .failure(error):
                return .failure(error as Error)
            }
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    func fetchFavoriteTVShows() async -> Result<TVShowListResultModel, Error> {
        // First get account info
        let accountResult: Result<AccountInfoModel, TMDBAPIError> = await request(.accountInfo)

        switch accountResult {
        case let .success(accountInfo):
            let accountId = String(accountInfo.id)
            let favoriteResult: Result<TVShowListResultModel, TMDBAPIError> = await request(
                .getFavoriteTVShows(accountId: accountId)
            )

            switch favoriteResult {
            case let .success(response):
                return .success(response)
            case let .failure(error):
                return .failure(error as Error)
            }
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    func discoverMovies(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        page: Int?,
        mediaType: DiscoverMediaType
    ) async -> Result<MovieListResultModel, Error> {
        let result: Result<MovieListResultModel, TMDBAPIError> = await request(
            .discoverMovie(
                keywords: keywords,
                cast: cast,
                genres: genres,
                watchProviders: watchProviders,
                watchRegion: watchRegion,
                includeAdult: false,
                language: "en-US",
                page: page
            )
        )

        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }

    func discoverTV(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        page: Int?
    ) async -> Result<TVShowListResultModel, Error> {
        let result: Result<TVShowListResultModel, TMDBAPIError> = await request(
            .discoverTV(
                keywords: keywords,
                cast: cast,
                genres: genres,
                watchProviders: watchProviders,
                watchRegion: watchRegion,
                includeAdult: false,
                language: "en-US",
                page: page
            )
        )

        switch result {
        case let .success(response):
            return .success(response)
        case let .failure(error):
            return .failure(error as Error)
        }
    }
}
#endif
