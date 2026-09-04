// iOS-only module: nothing in a macOS build depends on it (see `Package.swift`), but
// Xcode compiles every target of a local package regardless of reachability, so the
// guard is what actually keeps this out of the macOS build. It compiles to an empty
// module there. Removing these guards is the payoff of extracting a separate,
// iOS-only Package.swift.
#if canImport(UIKit)
protocol FetchFavoriteTVShowsUseCase {
    func execute() async -> Result<[Int], Error>
}

class FetchFavoriteTVShowsUseCaseImpl: FetchFavoriteTVShowsUseCase {
    private let repository: DiscoverRepository

    init(repository: DiscoverRepository) {
        self.repository = repository
    }

    func execute() async -> Result<[Int], Error> {
        return await repository.fetchFavoriteTVShows()
    }
}
#endif
