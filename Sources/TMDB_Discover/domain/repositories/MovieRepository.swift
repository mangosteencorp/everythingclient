// Repository Interface
protocol MovieRepository {
    func fetchNowPlayingMovies() async -> Result<[Movie], Error>
    func fetchUpcomingMovies() async -> Result<[Movie], Error>
    func fetchGenres() async -> Result<[Genre], Error>
    func fetchPopularPeople() async -> Result<[PopularPerson], Error>
    func fetchTrendingItems() async -> Result<[TrendingItem], Error>
    func toggleTVShowFavorite(tvShowId: Int, isFavorite: Bool) async -> Result<Bool, Error>
    func fetchFavoriteTVShows() async -> Result<[Int], Error>
    func discoverMovies(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        page: Int?
    ) async -> Result<[Movie], Error>
}
