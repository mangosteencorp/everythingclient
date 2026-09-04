// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
import TMDB_Shared_Backend

protocol APIServiceProtocol {
    func fetchGenres() async -> Result<GenreListModel, Error>
    func fetchTVGenres() async -> Result<GenreListModel, Error>
    func fetchPopularPeople() async -> Result<PersonListResultModel, Error>
    func fetchTrendingItems() async -> Result<TrendingAllResultModel, Error>
    func toggleTVShowFavorite(tvShowId: Int, isFavorite: Bool) async -> Result<Bool, Error>
    func fetchFavoriteTVShows() async -> Result<TVShowListResultModel, Error>
    func discoverMovies(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        page: Int?,
        mediaType: DiscoverMediaType
    ) async -> Result<MovieListResultModel, Error>
    func discoverTV(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        page: Int?
    ) async -> Result<TVShowListResultModel, Error>
}

class MovieRepositoryImpl: DiscoverRepository {
    private let apiService: APIServiceProtocol

    init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }

    func fetchNowPlayingMovies() async -> Result<[Movie], Error> {
        // Use discover API instead of specific endpoints
        return await discoverMovies(keywords: nil, cast: nil, genres: nil, watchProviders: nil, watchRegion: nil, page: nil)
    }

    func fetchUpcomingMovies() async -> Result<[Movie], Error> {
        // Use discover API instead of specific endpoints
        return await discoverMovies(keywords: nil, cast: nil, genres: nil, watchProviders: nil, watchRegion: nil, page: nil)
    }

    func fetchGenres() async -> Result<[Genre], Error> {
        let result = await apiService.fetchGenres()
        switch result {
        case let .success(response):
            return .success(response.genres.map { self.mapAPIGenreToEntity($0) })
        case let .failure(error):
            return .failure(error)
        }
    }

    func fetchTVGenres() async -> Result<[Genre], Error> {
        let result = await apiService.fetchTVGenres()
        switch result {
        case let .success(response):
            return .success(response.genres.map { self.mapAPIGenreToEntity($0) })
        case let .failure(error):
            return .failure(error)
        }
    }

    func fetchPopularPeople() async -> Result<[PopularPerson], Error> {
        let result = await apiService.fetchPopularPeople()
        switch result {
        case let .success(response):
            return .success(response.results.map { self.mapAPIPersonToEntity($0) })
        case let .failure(error):
            return .failure(error)
        }
    }

    func fetchTrendingItems() async -> Result<[TrendingItem], Error> {
        let result = await apiService.fetchTrendingItems()
        switch result {
        case let .success(response):
            // Filter out items with invalid media types (compactMap filters out nils)
            return .success(response.results.compactMap { self.mapAPITrendingToEntity($0) })
        case let .failure(error):
            return .failure(error)
        }
    }

    func toggleTVShowFavorite(tvShowId: Int, isFavorite: Bool) async -> Result<Bool, Error> {
        let result = await apiService.toggleTVShowFavorite(tvShowId: tvShowId, isFavorite: isFavorite)
        switch result {
        case let .success(success):
            return .success(success)
        case let .failure(error):
            return .failure(error)
        }
    }

    func fetchFavoriteTVShows() async -> Result<[Int], Error> {
        let result = await apiService.fetchFavoriteTVShows()
        switch result {
        case let .success(response):
            return .success(response.results.map { $0.id })
        case let .failure(error):
            return .failure(error)
        }
    }

    func discoverMovies(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        page: Int?,
        mediaType: DiscoverMediaType = .movie
    ) async -> Result<[Movie], Error> {
        let result = await apiService.discoverMovies(
            keywords: keywords,
            cast: cast,
            genres: genres,
            watchProviders: watchProviders,
            watchRegion: watchRegion,
            page: page,
            mediaType: mediaType
        )
        switch result {
        case let .success(response):
            return .success(response.results.map { self.mapAPIMovieToEntity($0) })
        case let .failure(error):
            return .failure(error)
        }
    }

    func discoverTV(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        page: Int?
    ) async -> Result<[Movie], Error> {
        let result = await apiService.discoverTV(
            keywords: keywords,
            cast: cast,
            genres: genres,
            watchProviders: watchProviders,
            watchRegion: watchRegion,
            page: page
        )
        switch result {
        case let .success(response):
            return .success(response.results.map { self.mapAPITVShowToEntity($0) })
        case let .failure(error):
            return .failure(error)
        }
    }

    private func mapAPIMovieToEntity(_ apiMovie: TMDBMovieModel) -> Movie {
        // Map API model to domain entity
        Movie(
            id: apiMovie.id,
            title: apiMovie.title,
            overview: apiMovie.overview,
            posterPath: apiMovie.poster_path,
            voteAverage: apiMovie.vote_average,
            popularity: apiMovie.popularity ?? 0,
            releaseDate: Movie.dateFormatter.date(from: apiMovie.release_date ?? "")
        )
    }

    private func mapAPIGenreToEntity(_ apiGenre: GenreModel) -> Genre {
        Genre(
            id: apiGenre.id,
            name: apiGenre.name
        )
    }

    private func mapAPIPersonToEntity(_ apiPerson: PersonModel) -> PopularPerson {
        PopularPerson(
            id: apiPerson.id,
            name: apiPerson.name,
            profilePath: apiPerson.profilePath,
            knownForDepartment: apiPerson.knownForDepartment,
            popularity: apiPerson.popularity
        )
    }

    private func mapAPITrendingToEntity(_ apiTrending: TrendingAllItem) -> TrendingItem? {
        // Convert string mediaType to enum, return nil if invalid
        guard let mediaType = TrendingItem.MediaType(rawValue: apiTrending.mediaType) else {
            return nil
        }

        return TrendingItem(
            id: apiTrending.id,
            title: apiTrending.title,
            name: apiTrending.name,
            posterPath: apiTrending.posterPath,
            backdropPath: apiTrending.backdropPath,
            overview: apiTrending.overview,
            mediaType: mediaType,
            popularity: apiTrending.popularity,
            voteAverage: apiTrending.voteAverage
        )
    }

    private func mapAPITVShowToEntity(_ apiTVShow: TVShow) -> Movie {
        // Map TVShow API model to Movie domain entity
        Movie(
            id: apiTVShow.id,
            title: apiTVShow.name,
            overview: apiTVShow.overview,
            posterPath: apiTVShow.poster_path,
            voteAverage: Float(apiTVShow.vote_average),
            popularity: Float(apiTVShow.popularity),
            releaseDate: Movie.dateFormatter.date(from: apiTVShow.first_air_date)
        )
    }
}
#endif
