// Repository Interface
protocol MovieRepository {
    func fetchNowPlayingMovies() async -> Result<[Movie], Error>
    func fetchUpcomingMovies() async -> Result<[Movie], Error>
    func fetchGenres() async -> Result<[Genre], Error>
    func fetchPopularPeople() async -> Result<[PopularPerson], Error>
    func fetchTrendingItems() async -> Result<[TrendingItem], Error>
}
