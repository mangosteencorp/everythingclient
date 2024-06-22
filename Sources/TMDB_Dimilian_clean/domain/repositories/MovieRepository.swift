// Repository Interface
protocol MovieRepository {
    func fetchNowPlayingMovies() async -> Result<[Movie], Error>
    func fetchUpcomingMovies() async -> Result<[Movie], Error>
}
