import TMDB_Shared_Backend

protocol APIServiceProtocol {
    func fetchGenres() async -> Result<GenreListModel, Error>
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
        page: Int?
    ) async -> Result<MovieListResultModel, Error>
}

class MovieRepositoryImpl: MovieRepository {
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
            return .success(response.results.map { self.mapAPITrendingToEntity($0) })
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
        page: Int?
    ) async -> Result<[Movie], Error> {
        let result = await apiService.discoverMovies(
            keywords: keywords,
            cast: cast,
            genres: genres,
            watchProviders: watchProviders,
            watchRegion: watchRegion,
            page: page
        )
        switch result {
        case let .success(response):
            return .success(response.results.map { self.mapAPIMovieToEntity($0) })
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

    private func mapAPITrendingToEntity(_ apiTrending: TrendingAllItem) -> TrendingItem {
        TrendingItem(
            id: apiTrending.id,
            title: apiTrending.title,
            name: apiTrending.name,
            posterPath: apiTrending.posterPath,
            backdropPath: apiTrending.backdropPath,
            overview: apiTrending.overview,
            mediaType: apiTrending.mediaType,
            popularity: apiTrending.popularity,
            voteAverage: apiTrending.voteAverage
        )
    }
}
