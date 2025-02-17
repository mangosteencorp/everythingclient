protocol TVShowRepository {
    func fetchAiringTodayTVShows() async -> Result<[TVShowEntity], Error>
    func fetchOnTheAirTVShows() async -> Result<[TVShowEntity], Error>
} 
