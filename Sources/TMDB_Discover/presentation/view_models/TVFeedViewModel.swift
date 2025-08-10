import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

class TVFeedViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchMoviesUseCase: FetchMoviesUseCase?
    private let fetchDiscoverMoviesUseCase: FetchDiscoverMoviesUseCase?
    private let fetchFavoriteTVShowsUseCase: FetchFavoriteTVShowsUseCase?
    private let toggleTVShowFavoriteUseCase: ToggleTVShowFavoriteUseCase?
    private let analyticsTracker: AnalyticsTracker?
    private let authViewModel: (any AuthenticationViewModelProtocol)?

    private var discoverParams: DiscoverMoviesParams?

    init(fetchMoviesUseCase: FetchMoviesUseCase? = nil,
         fetchDiscoverMoviesUseCase: FetchDiscoverMoviesUseCase? = nil,
         fetchFavoriteTVShowsUseCase: FetchFavoriteTVShowsUseCase? = nil,
         toggleTVShowFavoriteUseCase: ToggleTVShowFavoriteUseCase? = nil,
         analyticsTracker: AnalyticsTracker? = nil,
         authViewModel: (any AuthenticationViewModelProtocol)? = nil,
         discoverParams: DiscoverMoviesParams? = nil) {
        self.fetchMoviesUseCase = fetchMoviesUseCase
        self.fetchDiscoverMoviesUseCase = fetchDiscoverMoviesUseCase
        self.fetchFavoriteTVShowsUseCase = fetchFavoriteTVShowsUseCase
        self.toggleTVShowFavoriteUseCase = toggleTVShowFavoriteUseCase
        self.analyticsTracker = analyticsTracker
        self.authViewModel = authViewModel
        self.discoverParams = discoverParams
    }

    func fetchMovies() {
        isLoading = true
        errorMessage = nil

        Task {
            // Step 1: Load favorites first (if use case is available)
            var favoriteIds: Set<Int> = []
            if let favoritesUseCase = fetchFavoriteTVShowsUseCase {
                let favoritesResult = await favoritesUseCase.execute()
                switch favoritesResult {
                case let .success(favorites):
                    favoriteIds = Set(favorites)
                case let .failure(error):
                    // Log favorites error but continue loading movies
                    print("Failed to load favorites: \(error.localizedDescription)")
                }
            }

            // Step 2: Load movies
            // Prefer the discover API when available. If no params are set, use empty/default discover params.
            let result: Result<[Movie], Error>

            if let discoverUseCase = fetchDiscoverMoviesUseCase {
                let params = self.discoverParams ?? DiscoverMoviesParams()
                result = await discoverUseCase.execute(params: params)
            } else if let fetchUseCase = fetchMoviesUseCase {
                result = await fetchUseCase.execute()
            } else {
                result = .failure(NSError(domain: "TVFeedViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No use case available"]))
            }
            await MainActor.run {
                self.isLoading = false
                switch result {
                case let .success(movies):
                    // Merge favorite status into movies
                    self.movies = movies.map { movie in
                        var updatedMovie = movie
                        updatedMovie.isFavorite = favoriteIds.contains(movie.id)
                        return updatedMovie
                    }
                    analyticsTracker?.trackPageView(parameters: PageViewParameters(
                        screenName: "ListTVShows",
                        screenClass: "TVShowListContent"
                    ))
                case let .failure(error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func toggleFavorite(for movieId: Int) async {
        guard let toggleUseCase = toggleTVShowFavoriteUseCase else {
            await MainActor.run {
                self.errorMessage = "Favorite functionality not available"
            }
            return
        }

        // Check if authentication is required
        if toggleUseCase.requiresAuthentication() {
            await launchAuthentication()
            return
        }

        // Find the movie and toggle its favorite status
        guard let movieIndex = movies.firstIndex(where: { $0.id == movieId }) else { return }
        let currentFavoriteStatus = movies[movieIndex].isFavorite
        let newFavoriteStatus = !currentFavoriteStatus

        // Optimistically update UI
        await MainActor.run {
            self.movies[movieIndex].isFavorite = newFavoriteStatus
        }

        // Make API call
        let result = await toggleUseCase.execute(tvShowId: movieId, isFavorite: newFavoriteStatus)

        switch result {
        case .success:
            // Success - UI already updated optimistically
            break
        case let .failure(error):
            // Revert UI change on failure
            await MainActor.run {
                self.movies[movieIndex].isFavorite = currentFavoriteStatus
                if case FavoriteError.authenticationRequired = error {
                    self.errorMessage = "Please sign in to favorite movies"
                } else {
                    self.errorMessage = "Failed to update favorite: \(error.localizedDescription)"
                }
            }
        }
    }

    private func launchAuthentication() async {
        guard let authViewModel = authViewModel else {
            await MainActor.run {
                self.errorMessage = "Authentication not available"
            }
            return
        }

        await authViewModel.signIn()
    }

    private func hasDiscoverParams(_ params: DiscoverMoviesParams) -> Bool {
        return params.keywords != nil || params.cast != nil || params.genres != nil || params.watchProviders != nil
    }

    func setDiscoverParams(_ params: DiscoverMoviesParams) {
        discoverParams = params
    }
}
