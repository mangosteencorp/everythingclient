// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
// Repository Interface
protocol DiscoverRepository {
    func fetchNowPlayingMovies() async -> Result<[Movie], Error>
    func fetchUpcomingMovies() async -> Result<[Movie], Error>
    func fetchGenres() async -> Result<[Genre], Error>
    func fetchTVGenres() async -> Result<[Genre], Error>
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
        page: Int?,
        mediaType: DiscoverMediaType
    ) async -> Result<[Movie], Error>
    func discoverTV(
        keywords: Int?,
        cast: Int?,
        genres: [Int]?,
        watchProviders: [Int]?,
        watchRegion: String?,
        page: Int?
    ) async -> Result<[Movie], Error>
}
#endif
