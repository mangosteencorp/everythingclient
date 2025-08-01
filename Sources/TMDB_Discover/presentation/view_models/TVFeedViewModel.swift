import CoreFeatures
import SwiftUI
import TMDB_Shared_Backend

class TVFeedViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchMoviesUseCase: FetchMoviesUseCase
    private let fetchFavoriteTVShowsUseCase: FetchFavoriteTVShowsUseCase?
    private let toggleTVShowFavoriteUseCase: ToggleTVShowFavoriteUseCase?
    private let analyticsTracker: AnalyticsTracker?
    private let authViewModel: (any AuthenticationViewModelProtocol)?

    init(fetchMoviesUseCase: FetchMoviesUseCase,
         fetchFavoriteTVShowsUseCase: FetchFavoriteTVShowsUseCase? = nil,
         toggleTVShowFavoriteUseCase: ToggleTVShowFavoriteUseCase? = nil,
         analyticsTracker: AnalyticsTracker? = nil,
         authViewModel: (any AuthenticationViewModelProtocol)? = nil) {
        self.fetchMoviesUseCase = fetchMoviesUseCase
        self.fetchFavoriteTVShowsUseCase = fetchFavoriteTVShowsUseCase
        self.toggleTVShowFavoriteUseCase = toggleTVShowFavoriteUseCase
        self.analyticsTracker = analyticsTracker
        self.authViewModel = authViewModel
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
            let result = await fetchMoviesUseCase.execute()
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
}
